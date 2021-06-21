/*  Copyright (C) 2011-2015  P.D. Buchan (pdbuchan@yahoo.com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Send a "cooked" IPv6 UDP packet via raw socket.
// Need to specify destination MAC address.
// Includes some UDP data.

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>           // close()
#include <string.h>           // strcpy, memset(), and memcpy()

#include <netdb.h>            // struct addrinfo
#include <sys/types.h>        // needed for socket(), uint8_t, uint16_t
#include <sys/socket.h>       // needed for socket()
#include <netinet/in.h>       // IPPROTO_RAW, IPPROTO_UDP, INET6_ADDRSTRLEN
#include <netinet/ip.h>       // IP_MAXPACKET (which is 65535)
#include <netinet/ip6.h>      // struct ip6_hdr
#include <netinet/udp.h>      // struct udphdr
#include <arpa/inet.h>        // inet_pton() and inet_ntop()
#include <sys/ioctl.h>        // macro ioctl is defined
#include <bits/ioctls.h>      // defines values for argument "request" of ioctl.
#include <net/if.h>           // struct ifreq
#include <linux/if_ether.h>   // ETH_P_IP = 0x0800, ETH_P_IPV6 = 0x86DD
#include <linux/if_packet.h>  // struct sockaddr_ll (see man 7 packet)
#include <net/ethernet.h>

#include <errno.h>            // errno, perror()

// Define some constants.
#define IP6_HDRLEN 40         // IPv6 header length
#define UDP_HDRLEN  8         // UDP header length, excludes data

// Function prototypes
uint16_t checksum (uint16_t *addr, int len);
uint16_t udp6_checksum (struct ip6_hdr, struct udphdr, uint8_t *, int);
char *allocate_strmem (int);
uint8_t *allocate_ustrmem (int);

int
main (int argc, char **argv) {

  int i, status, datalen, frame_length, sd, bytes;
  char *interface, *target, *src_ip, *dst_ip;
  struct ip6_hdr iphdr;
  struct udphdr udphdr;
  uint8_t *data, *src_mac, *dst_mac, *ether_frame;
  struct addrinfo hints, *res;
  struct sockaddr_in6 *ipv6;
  struct sockaddr_ll device;
  struct ifreq ifr;
  void *tmp;

  // Allocate memory for various arrays.
  src_mac = allocate_ustrmem (6);
  dst_mac = allocate_ustrmem (6);
  data = allocate_ustrmem (IP_MAXPACKET);
  ether_frame = allocate_ustrmem (IP_MAXPACKET);
  interface = allocate_strmem (INET6_ADDRSTRLEN);
  target = allocate_strmem (INET6_ADDRSTRLEN);
  src_ip = allocate_strmem (INET6_ADDRSTRLEN);
  dst_ip = allocate_strmem (INET6_ADDRSTRLEN);


  printf("STARTING...");
  // Submit request for a socket descriptor to look up interface.
  if ((sd = socket (PF_PACKET, SOCK_DGRAM, IPPROTO_RAW)) < 0) {
    perror ("socket() failed to get socket descriptor for using ioctl() ");
    exit (EXIT_FAILURE);
  }


//  strcpy (interface, "enp9s0");
  strcpy (interface, "eth4");
  // Find interface index from interface name and store index in
  // struct sockaddr_ll device, which will be used as an argument of sendto().
  memset (&device, 0, sizeof (device));

  if ((device.sll_ifindex = if_nametoindex (interface)) == 0) {
    perror ("if_nametoindex() failed to obtain interface index ");
    exit (EXIT_FAILURE);
  }
  

  char mac[]={0,0,0,0,0,0};
  memcpy (src_mac,mac,12);
  char mac2[]={0x33,0x33,0x00,0x00,0x01,0x14};
  memcpy (dst_mac,mac2,12);

  // Source IPv6 address: you need to fill this out
  strcpy (src_ip, "fd74:6f6d:7368:7f02::fd");

  // Destination URL or IPv6 address: you need to fill this out
  strcpy (dst_ip, "ff02::114");

  // Fill out sockaddr_ll.
  device.sll_family = AF_PACKET;
  device.sll_protocol = htons (ETH_P_IPV6);
  memcpy (device.sll_addr, dst_mac, 6 * sizeof (uint8_t));
  device.sll_halen = 6;


//Deal with the key
char key[]="d06fba883a5cf7fbad1ea21ee927f22bc10b58fd0cc7572ca691d806553a9024";
const char *pos = key;
unsigned char keyb[(strlen(key)/2)+1];
    for (size_t count = 0; count < sizeof keyb/sizeof *keyb; count++) {
        sscanf(pos, "%2hhx", &keyb[count]);
        pos += 2;
    }
    keyb[32]=0;

// Add desitionation
  int ipos;
  ipos=0;
  char dst[strlen(src_ip)+4+3];
  dst[0]='[';
   printf("%s\n\n\n",dst);
  memcpy(&dst[1],src_ip,strlen(src_ip));
  ipos=ipos+strlen(src_ip)+1;
  dst[ipos++]=']'; 
  dst[ipos++]=':';
  dst[ipos++]='1';
  dst[ipos++]='0';
  dst[ipos++]='2';
  dst[ipos++]='4';
  dst[ipos]=0;

//udp data
  ipos=0;

  memcpy(data,&keyb,strlen(keyb));
  ipos=ipos + strlen(keyb);
  memcpy(data+ipos,&dst,strlen(dst));  
  datalen=strlen(data);




  // IPv6 header

  // IPv6 version (4 bits), Traffic class (8 bits), Flow label (20 bits)
  iphdr.ip6_flow = htonl ((6 << 28) | (0 << 20) | 0);

  // Payload length (16 bits): UDP header + UDP data
  iphdr.ip6_plen = htons (UDP_HDRLEN + datalen);

  // Next header (8 bits): 17 for UDP
  iphdr.ip6_nxt = IPPROTO_UDP;

  // Hop limit (8 bits): default to maximum value
  iphdr.ip6_hops = 255;

  // Source IPv6 address (128 bits)
  if ((status = inet_pton (AF_INET6, src_ip, &(iphdr.ip6_src))) != 1) {
    fprintf (stderr, "inet_pton() failed.\nError message: %s", strerror (status));
    exit (EXIT_FAILURE);
  }

  // Destination IPv6 address (128 bits)
  if ((status = inet_pton (AF_INET6, dst_ip, &(iphdr.ip6_dst))) != 1) {
    fprintf (stderr, "inet_pton() failed.\nError message: %s", strerror (status));
    exit (EXIT_FAILURE);
  }

  // UDP header

  // Source port number (16 bits): pick a number
  udphdr.source = htons (9001);

  // Destination port number (16 bits): pick a number
  udphdr.dest = htons (9001);

  // Length of UDP datagram (16 bits): UDP header + UDP data
  udphdr.len = htons (UDP_HDRLEN + datalen);

  // UDP checksum (16 bits)
  udphdr.check = udp6_checksum (iphdr, udphdr, data, datalen);

  // Fill out ethernet frame header.

  // Ethernet frame length = ethernet data (IP header + UDP header + UDP data)
  frame_length = IP6_HDRLEN + UDP_HDRLEN + datalen;

  // IPv6 header
  memcpy (ether_frame, &iphdr, IP6_HDRLEN * sizeof (uint8_t));

  // UDP header
  memcpy (ether_frame + IP6_HDRLEN, &udphdr, UDP_HDRLEN * sizeof (uint8_t));

  // UDP data
  memcpy (ether_frame + IP6_HDRLEN + UDP_HDRLEN, data, datalen * sizeof (uint8_t));

  // Open raw socket descriptor.
  if ((sd = socket (PF_PACKET, SOCK_DGRAM, htons (ETH_P_ALL))) < 0) {
    perror ("socket() failed ");
    exit (EXIT_FAILURE);
  }

  // Send ethernet frame to socket.
  if ((bytes = sendto (sd, ether_frame, frame_length, 0, (struct sockaddr *) &device, sizeof (device))) <= 0) {
    perror ("sendto() failed");
    exit (EXIT_FAILURE);
  }

  close (sd);

  // Free allocated memory.
  free (src_mac);
  free (dst_mac);
  free (data);
  free (ether_frame);
  free (interface);
  free (target);
  free (src_ip);
  free (dst_ip);

  return (EXIT_SUCCESS);
}

// Computing the internet checksum (RFC 1071).
// Note that the internet checksum is not guaranteed to preclude collisions.
uint16_t
checksum (uint16_t *addr, int len) {

  int count = len;
  register uint32_t sum = 0;
  uint16_t answer = 0;

  // Sum up 2-byte values until none or only one byte left.
  while (count > 1) {
    sum += *(addr++);
    count -= 2;
  }

  // Add left-over byte, if any.
  if (count > 0) {
    sum += *(uint8_t *) addr;
  }

  // Fold 32-bit sum into 16 bits; we lose information by doing this,
  // increasing the chances of a collision.
  // sum = (lower 16 bits) + (upper 16 bits shifted right 16 bits)
  while (sum >> 16) {
    sum = (sum & 0xffff) + (sum >> 16);
  }

  // Checksum is one's compliment of sum.
  answer = ~sum;

  return (answer);
}

// Build IPv6 UDP pseudo-header and call checksum function (Section 8.1 of RFC 2460).
uint16_t
udp6_checksum (struct ip6_hdr iphdr, struct udphdr udphdr, uint8_t *payload, int payloadlen) {

  char buf[IP_MAXPACKET];
  char *ptr;
  int chksumlen = 0;
  int i;

  ptr = &buf[0];  // ptr points to beginning of buffer buf

  // Copy source IP address into buf (128 bits)
  memcpy (ptr, &iphdr.ip6_src.s6_addr, sizeof (iphdr.ip6_src.s6_addr));
  ptr += sizeof (iphdr.ip6_src.s6_addr);
  chksumlen += sizeof (iphdr.ip6_src.s6_addr);

  // Copy destination IP address into buf (128 bits)
  memcpy (ptr, &iphdr.ip6_dst.s6_addr, sizeof (iphdr.ip6_dst.s6_addr));
  ptr += sizeof (iphdr.ip6_dst.s6_addr);
  chksumlen += sizeof (iphdr.ip6_dst.s6_addr);

  // Copy UDP length into buf (32 bits)
  memcpy (ptr, &udphdr.len, sizeof (udphdr.len));
  ptr += sizeof (udphdr.len);
  chksumlen += sizeof (udphdr.len);

  // Copy zero field to buf (24 bits)
  *ptr = 0; ptr++;
  *ptr = 0; ptr++;
  *ptr = 0; ptr++;
  chksumlen += 3;

  // Copy next header field to buf (8 bits)
  memcpy (ptr, &iphdr.ip6_nxt, sizeof (iphdr.ip6_nxt));
  ptr += sizeof (iphdr.ip6_nxt);
  chksumlen += sizeof (iphdr.ip6_nxt);

  // Copy UDP source port to buf (16 bits)
  memcpy (ptr, &udphdr.source, sizeof (udphdr.source));
  ptr += sizeof (udphdr.source);
  chksumlen += sizeof (udphdr.source);

  // Copy UDP destination port to buf (16 bits)
  memcpy (ptr, &udphdr.dest, sizeof (udphdr.dest));
  ptr += sizeof (udphdr.dest);
  chksumlen += sizeof (udphdr.dest);

  // Copy UDP length again to buf (16 bits)
  memcpy (ptr, &udphdr.len, sizeof (udphdr.len));
  ptr += sizeof (udphdr.len);
  chksumlen += sizeof (udphdr.len);

  // Copy UDP checksum to buf (16 bits)
  // Zero, since we don't know it yet
  *ptr = 0; ptr++;
  *ptr = 0; ptr++;
  chksumlen += 2;

  // Copy payload to buf
  memcpy (ptr, payload, payloadlen * sizeof (uint8_t));
  ptr += payloadlen;
  chksumlen += payloadlen;

  // Pad to the next 16-bit boundary
  for (i=0; i<payloadlen%2; i++, ptr++) {
    *ptr = 0;
    ptr++;
    chksumlen++;
  }

  return checksum ((uint16_t *) buf, chksumlen);
}

// Allocate memory for an array of chars.
char *
allocate_strmem (int len) {

  void *tmp;

  if (len <= 0) {
    fprintf (stderr, "ERROR: Cannot allocate memory because len = %i in allocate_strmem().\n", len);
    exit (EXIT_FAILURE);
  }

  tmp = (char *) malloc (len * sizeof (char));
  if (tmp != NULL) {
    memset (tmp, 0, len * sizeof (char));
    return (tmp);
  } else {
    fprintf (stderr, "ERROR: Cannot allocate memory for array allocate_strmem().\n");
    exit (EXIT_FAILURE);
  }
}

// Allocate memory for an array of unsigned chars.
uint8_t *
allocate_ustrmem (int len) {

  void *tmp;

  if (len <= 0) {
    fprintf (stderr, "ERROR: Cannot allocate memory because len = %i in allocate_ustrmem().\n", len);
    exit (EXIT_FAILURE);
  }

  tmp = (uint8_t *) malloc (len * sizeof (uint8_t));
  if (tmp != NULL) {
    memset (tmp, 0, len * sizeof (uint8_t));
    return (tmp);
  } else {
    fprintf (stderr, "ERROR: Cannot allocate memory for array allocate_ustrmem().\n");
    exit (EXIT_FAILURE);
  }
}
