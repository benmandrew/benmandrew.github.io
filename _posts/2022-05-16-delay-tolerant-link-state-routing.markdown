---
layout:     post
title:      "Dissertation Project: Delay-Tolerant Link-State Routing"
date:       2022-05-16
categories: articles
header:     /assets/headers/dtlsr.png
---

This is my third-year dissertation project for the University of Cambridge Computer Science Tripos. The project is to evaluate and compare the performance of routing protocols LSR and DTLSR in a variety of network topologies and situations, to determine where delay-tolerant modifications improve or worsen performance. Both protocols are modelled off of standard OSPF, but implemented completely from scratch.

LSR and DTLSR are *routing* protocols for running on network routers. They use a *link-state* representation of the network topology for routing. DTLSR is LSR with modifications that allow it to perform better in unreliable, variable-delay network conditions, making it *delay-tolerant*.

##### Links:

- The [Dissertation Itself](https://mainbucketbenandrew.s3.amazonaws.com/dtlsr/DTLSR.pdf) (PDF)</li>
- DTLSR [GitHub repository](https://github.com/benmandrew/DTLSR)</li>
