---
layout:     post
title:      "Dummy's Guide to Logic and Proof"
date:       2023-02-18
categories: articles
tag:        "Article"
header:     headers/dummy-logic.png
header_rendering: auto
banner: true
---

It's fair to say that logic gets a bit of a bad rap. Even a toddler knows the difference between true and false, so why not spend time pondering sexier mathematical problems (relatively speaking of course) that seem more interesting? Unfortunately, it turns out that logic is not so simple, and even the smartest people in the world can make incorrect leaps of reasoning based off no more than "it feels right". Logic is here to be the fun police, and make sure that when people make arguments and come to conclusions, that they are _well-founded_.

But what actually is logic? Logic is simply the study of reasoning and consequence: starting from a set of assumptions about the world, which conclusions can we deduce that are correct?

Logic gives us the what, but it's also fairly important to work out exactly how we come to and verify conclusions. A _proof_ is the mechanical process in which we go from our assumptions to the desired conclusion, like a baking recipe starting with raw ingredients and ending with something tasty.

As an example we can use _logical deduction_ (fancy name, simple idea). We start with two assumptions: **"it is raining"**, and **"if it is raining, then I am wet"**. It's not a huge leap to conclude from these two assumptions that I am in fact wet. This is all well and good, but we want to be able to talk about _all_ possible things, not just the weather. So, instead we can use symbols to write both more concisely, and in a more general way. We'll choose $$A$$ to mean **"it is raining"**, $$B$$ to mean **"I am wet"**, and $$A \rightarrow B$$ to mean **"if it is raining then I am wet"**. $$A \rightarrow B$$ generally means, **"if $$A$$ then $$B$$"**, so you may be able to see the reasoning behind using the arrow.

To go from the assumptions ($$A$$ and $$A \rightarrow B$$) to the conclusion ($$B$$) we need an _inference rule_. This is laid out around a horizontal line: the things we assume are on top and the thing we conclude is on the bottom. The fancy Latin name for this is _modus ponens_, and it is one of the most important concepts in logic.

$$
\begin{prooftree}
\AxiomC{$A$}
\AxiomC{$A \rightarrow B$}
\BinaryInfC{$B$}
\end{prooftree}
$$

We can imagine a set of assumptions that is slightly more complicated: along with **"it is raining"** ($$A$$) and **"if it is raining then I am wet"** ($$A \rightarrow B$$), we include **"if I am wet then I am miserable"** ($$B \rightarrow C$$). From this we want to conclude that **"I am miserable"** ($$C$$). In order to prove this we have to use our inference rule twice! We first do the same as we did above, giving us $$B$$ (**"I am wet"**), and then we can apply the rule again but using $$B$$ and $$B \rightarrow C$$ as the assumptions, giving us $$C$$. In the notation, we show multiple rule applications like so:

$$
\begin{prooftree}
\AxiomC{$A$}
\AxiomC{$A \rightarrow B$}
\BinaryInfC{$B$}
\AxiomC{$B \rightarrow C$}
\BinaryInfC{$C$}
\end{prooftree}
$$

This gives us a tree-like structure: at the bottom---the root of the tree---we have our conclusion, and above it we have branches---inference rules---leading up to leaves at the top, which are our starting assumptions. Keep in mind that when we have symbols $$A$$, $$B$$, $$C$$, etc. that these could mean anything, not just about my lack of preparedness for bad weather.

Up until now we have included only one rule, modus ponens. However, it can be very useful to include other rules that help us to do more intuitive proofs. As an example we have the idea of two things having to be true at once. If we want to say that both $$A$$ and $$B$$ have to be true, then we write $$A \wedge B$$. The inference rule below says that in order to claim $$A \wedge B$$, we must have individually shown that $$A$$ is true and that $$B$$ is true.

$$
\begin{prooftree}
\AxiomC{$A$}
\AxiomC{$B$}
\BinaryInfC{$A \wedge B$}
\end{prooftree}
$$

We also have the idea of having one thing being true or the other (or both). In order to say $$A \vee B$$ ($$A$$ _or_ $$B$$) we either have to show that $$A$$ is true, or we can show that $$B$$ is true.

$$
\begin{prooftree}
\AxiomC{$A$}
\UnaryInfC{$A \vee B$}
\end{prooftree}
\quad\quad\quad\quad
\begin{prooftree}
\AxiomC{$B$}
\UnaryInfC{$A \vee B$}
\end{prooftree}
$$

It's worth keeping in mind here that these connectives ($$\rightarrow$$, $$\wedge$$, $$\vee$$) don't just apply to single facts, $$A$$ and $$B$$ and so on can represent _any_ already constructed formula. For example, we may have $$A \wedge (B \vee C)$$, which can be proven by showing that $$A$$ is true, as well as either $$B$$ or $$C$$.

Let's use these inference rules by proving a more complicated statement. We will assume that **"the cat is inside"** ($$A$$), **"if the cat is inside then it wants to go outside"** ($$A \rightarrow B$$), and **"if the cat is inside then the dog is outside"** ($$A \rightarrow C$$). We want to conclude that both that **"the cat wants to go outside"** _and_ that **"the dog is outside"** ($$B \wedge C$$).

$$
\begin{prooftree}
\AxiomC{$A$}
\AxiomC{$A\rightarrow B$}
\BinaryInfC{$B$}
\AxiomC{$A$}
\AxiomC{$A\rightarrow C$}
\BinaryInfC{$C$}
\BinaryInfC{$B \wedge C$}
\end{prooftree}
$$

We see again the tree-like structure of proofs. There are two ways of reading proof trees like this, from top to bottom or bottom to top. Top to bottom is called _forward reasoning_, we start with our assumptions and we start generating new things that we know to be true given these assumptions; in this case we know that $$A$$ and $$A\rightarrow B$$, so we conclude $$B$$. Reading from bottom to top is called _backward reasoning_, we start with the thing we want to prove, and we explore different ways of proving that statement using the rules. While you may find forward reasoning more intuitive at first, for large proofs with lots of leaves at the top it can be difficult to know what you need to start with, whereas in backward reasoning we _always_ start at a single point (the root) and explore outwards, finishing branches once we reach our assumptions.

What I describe here is just a particular example of a proof system, I make no claims that it's any good!

Another thing to note is that there has been no proper discussion of the _meaning_ of these statements in the real world. Sure, we may have concluded that I am wet and miserable but this is completely dependent on the assumptions we made, we can't be sure we're saying anything about the real world that's actually correct! For example imagine if I want to show that **"If it is raining, then there is water falling from the sky"** ($$A \rightarrow B$$). While in the real world this is obviously true (by the definition of 'raining'!), our proof system doesn't allow us to prove that it is the case.

## Semantics

Let's pick a semantics that minimises the complexity as much as possible. When we have a symbol $$A$$, it will simply be _true_ or _false_. That's it. We can then define the semantics of our connecting symbols as depending on their two inputs, as in the table below. It's worth going through each line and making sure that you understand why the connective is true or false.

The new $$\neg$$ symbol is for 'negation'. This generally means that if $$A$$ says that something is the case (**"I like chocolate"**), then $$\neg A$$ means that it is not the case (**"I don't like chocolate"**). Here it just flips true to false and vice-versa.

<div style="overflow-x:auto;">
<table class="truth-table" align="center" style="margin-top: 2rem; margin-bottom: 2rem;">
  <tr>
    <th>$$A$$</th>
    <th>$$B$$</th>
    <th>$$A\wedge B$$</th>
    <th>$$A\vee B$$</th>
    <th>$$A\rightarrow B$$</th>
    <th>$$\neg A$$</th>
  </tr>
  <tr>
    <td>true</td>
    <td>true</td>
    <td>true</td>
    <td>true</td>
    <td>true</td>
    <td>false</td>
  </tr>
  <tr>
    <td>true</td>
    <td>false</td>
    <td>false</td>
    <td>true</td>
    <td>false</td>
    <td>false</td>
  </tr>
  <tr>
    <td>false</td>
    <td>true</td>
    <td>false</td>
    <td>true</td>
    <td>true</td>
    <td>true</td>
  </tr>
  <tr>
    <td>false</td>
    <td>false</td>
    <td>false</td>
    <td>false</td>
    <td>true</td>
    <td>true</td>
  </tr>
</table>
</div>

(One common difficulty is understanding why if $$A$$ is false then $$A\rightarrow B$$ is always true, no matter what $$B$$ is. The reasoning behind this can get fairly complex and philosophical, if you'd like to know more then look up 'material implication'.)

This semantics gives us the opportunity to make claims about the world that have no assumptions, in other words claims that are simply true! For example, we have the statement $$A \rightarrow A$$, saying that if $$A$$ then $$A$$. This is obviously always true, but as our previous proof system didn't have a proper semantics, we couldn't justify it!

To show that $$A \rightarrow A$$ is _always_ true, we can exhaustively check all the possibilities for the input $$A$$, shown in the table below. Another very useful statement that is always true is $$A \vee \neg A$$, which says that $$A$$ _must_ either be true or false, it cannot be anything else. (You can verify both of these by checking against the table above.) 

<table class="truth-table" align="center" style="margin-top: 2rem; margin-bottom: 2rem;">
  <tr>
    <th>$$A$$</th>
    <th>$$A\rightarrow A$$</th>
    <th>$$A\vee\neg A$$</th>
  </tr>
  <tr>
    <td>true</td>
    <td>true</td>
    <td>true</td>
  </tr>
  <tr>
    <td>false</td>
    <td>true</td>
    <td>true</td>
  </tr>
</table>

We take statements like this that are obviously true and call them _axioms_. These aren't simple assumptions---their truth is backed only by the semantics that we've chosen---but we can use them like assumptions, as leaves at the top of proof trees.

For example, we may want to prove that $$A \rightarrow (A \vee B)$$, which says that if $$A$$ is true then $$A$$ or $$B$$ is true. Without the axioms this would be impossible to prove with our old purely syntactical system, but with the axiom $$A \rightarrow A$$ and the rules for $$\vee$$ we can do:

$$
\begin{prooftree}
\AxiomC{$A \rightarrow A$}
\UnaryInfC{$A \rightarrow (A \vee B)$}
\end{prooftree}
$$

Note how instead of picking the $$A$$ in $$A\vee B$$ we may have picked $$B$$ using the other rule for $$\vee$$. This would have caused us to get stuck, and we would have had to roll back and try the other option. Thus we can see for the proof system we have here one can't just blindly apply the rules and hope to find a proof first try.

Since we've proved $$A \rightarrow (A \vee B)$$ without any assumptions, using only axioms, we know that it is always true no matter what. Thus, $$A \rightarrow (A \vee B)$$ is what is called a _tautology_, a statement that is always true. This is different from an axiom, as an axiom is a statement that we concluded from the semantics, whereas tautologies are proved using the proof system.

## Conclusion

In sum, we've seen how logic can be used to make claims about the world given assumptions, how proof systems give us a mechanical way of going from the assumptions to the conclusion, and then how to connect the logic and the proof system to the real world using a semantics, which allows us to talk about tautologies: statements that are always true without previous assumptions.


### Further reading

- The logic and proof course at Cambridge University, from which most of my foundational knowledge comes from ([link](https://www.cl.cam.ac.uk/teaching/2223/LogicProof/logic-notes.pdf)). This is a much more complete work than what I have here, but assumes that the reader is a 2nd year computer science student. Highly recommended.

- You may think that having symbols simply be _true_ or _false_ doesn't allow us to say much about the real world, and you would be right! This is what is called _propositional logic_, but we can extend it to talk about many more things by using _first-order logic_. There are plenty of good resources about this online, not least the course notes above.
