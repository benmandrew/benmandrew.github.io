---
layout:     post
title:      "Delay-Tolerant Link-State Routing"
date:       2022-05-16
categories: articles
tag:        "Dissertation Project"
header:     headers/dtlsr.png
header_rendering: auto
banner: true
---

This is my third-year dissertation project for the University of Cambridge Computer Science Tripos. The project is to evaluate and compare the performance of routing protocols LSR and DTLSR in a variety of network topologies and situations, to determine where delay-tolerant modifications improve or worsen performance. Both protocols are modelled off of standard OSPF, but implemented completely from scratch.

The protocols are evaluated on the Common Open Research Emulator (CORE), a network emulator released by the U.S Naval Research Laboratory ([link](https://www.nrl.navy.mil/Our-Work/Areas-of-Research/Information-Technology/NCS/CORE/)).

LSR and DTLSR are *routing* protocols for running on network routers. They use a *link-state* representation of the network topology for routing. DTLSR is LSR with modifications that allow it to perform better in unreliable, variable-delay network conditions, making it *delay-tolerant*.

##### Links:

- The [dissertation itself]({{ site.s3_path }}/dtlsr/dtlsr.pdf) (PDF).
- DTLSR [GitHub repository](https://github.com/benmandrew/DTLSR).
