# Math on "Convenience Shop" Calculations

It is known that the Gold required for your $n$-th visit to the altar is

$$a_n=10\left(n^2-n+2\right) \quad \left(n\in{\mathbb N}_+\right)$$

Since it is always a multiple of 10, we will thus consider its one-tenth value for the convenience of analysis below.

It can thus be calculated that the total amount of Gold required for all your first $n$ visits to the altar, $S_n$, satisfies

$$\frac{S_n}{10}=\sum_{i=1}^n{\frac{a_i}{10}}=\frac13 n\left(n^2+5\right)\in{\mathbb N}_+ \quad \left(n\in{\mathbb N}_0\right)$$

With that, we can then calculate the Gold required for your next $m$ visits to the altar after your $n$-th visit, $T_{n,m}$, which is something we care more about:

```math
\begin{aligned}
\frac{T_{n,m}}{10}=\frac{S_{n+m}-S_n}{10}&=\frac13\left[(n+m)\left((n+m)^2+5\right)-n\left(n^2+5\right)\right]\\
&=\frac13 \left(m^3+3nm^2+(3n^2+5)m\right)\in{\mathbb N}_+
\end{aligned}
```

## Turning Inequation into Equation

We would like to know the maximum number of visits you can pay before you run out of Gold ($G$), that is, the maximum value of $m$ at given $n$ and $G$ values such that $T_{n,m}\le G$. Since the left-hand side, $T_{n,m}$, is a multiple of 10, we can conveniently consider instead

$$\frac{T_{n,m}}{10}\le \left\lfloor \frac {G}{10}\right\rfloor$$

which can be rearranged into the following inequation:

$$m^3+3nm^2+(3n^2+5)m-\left\lfloor \frac {3G}{10}\right\rfloor \le 0$$

Recall that we are solving the maximum $m$ (variable) at given $n$ and $G$ (constants). To facilitate our further analysis, we let $x=m+n$, so the left-hand side

$${\rm LHS}=f(x)=x^3+5x-q,\quad {\rm where}\ q=n\left(n^2+5\right)+\left\lfloor \frac {3G}{10}\right\rfloor$$

We note two things:
1. The opposite of the constant term $q=3\left(S_n+\left\lfloor\frac G{10}\right\rfloor\right)>0$
2. The derivative $f^\prime(x)=3x^2+5\ge 0, \forall x\in{\mathbb R}$

The second attribute is good in that it guarantees that $f(x)$ increases monotonically, so there will only be one real-number root $x_0$ for equation $f(x)=0$. It is also obvious that $x_0 \ge n \ge 0$. Therefore, the maximum positive integer $m$ we seek for should simply be $\left\lfloor x_0 \right\rfloor-n$.

## Solving the Cubic Equation

Now our target becomes solving the equation instead of the inequation.

According to [Cardano's formula](https://en.wikipedia.org/wiki/Cubic_equation#Cardano's_formula), the root

$$x_0=\sqrt[3]u + \sqrt[3]v$$

where $u$ and $v$ are the two roots of the quadratic equation

$$g(t)=t^2-qt-\frac{p^3}{27}=0,\ {\rm where}\ p=5$$

We note that its discriminant

$$\Delta=q^2+\frac{500}{27}>q^2>0$$

further confirming that there is only one real root for the cubic equation (according to Cardano's formula), which is then calculated to be

$$x_0=\sqrt[3]{\frac{\sqrt{\Delta}+q}2} - \sqrt[3]{\frac{\sqrt{\Delta}-q}2}$$

Finally, according to the discussion in the previous section, the maximum value of $m$ should be $m_0=\left\lfloor x_0 \right\rfloor-n$.

## When It Comes to Programming...

Although we obtained an accurate analytical solution in the previous section, that method might have some practical issues on its precision because floating-point operations are involved. Especially, if $q\sim 10^8$, when calculating $q^2 > 2^{53}$, which is needed according to the formula of $x_0$, [all information in the fractional part will be lost](https://en.wikipedia.org/wiki/Double-precision_floating-point_format).

> [!note]
> <i>Of course, in a normal TSW game, you won't be able to visit an altar for more than 22 times; even in the 3rd (or above) round of the game, $m$ is almost certainly no more than 25. But with `tswKai3`, players are allowed to cheat and therefore will be able to achieve $m \sim 10^4$.</i>

Additionally, floating-point operation is slower than integer operations, so the number of such operations should be minimized when possible.

We note that

```math
\begin{aligned}
f(x_1)=5r&>0,\quad {\rm where}\ x_1=r=\sqrt[3]{q}>0\\
f(x_2)=-3r^2+8r-6&<0,\quad {\rm where}\ x_2=r-1
\end{aligned}
```

The second inequation holds because ${\rm LHS} = -3\left(r-\frac43\right)^2-\frac23<0,\ \forall r\in\{\mathbb R}$.

Therefore, according to intermediate value theorem, the desired root should be

$$x_0\in\left(\sqrt[3]{q}-1,\sqrt[3]{q}\right)$$

With this knowledge, however, we still don't yet know whether $m_0$ (Recall $m_0=\left\lfloor x_0 \right\rfloor-n$) is, eventually, either $m_1=\left\lfloor \sqrt[3]{q} \right\rfloor-n$ or its adjacent smaller integer, $m_1-1$. Therefore, we will need to evaluate the value of $f(m_1)$ and compare it with 0.
* If $f(m_1)\le0$, then $m_0=m_1=\left\lfloor \sqrt[3]{q} \right\rfloor-n$
* If $f(m_1)>0$, then $m_0=m_1-1=\left\lfloor \sqrt[3]{q} \right\rfloor-n-1$

This algorithm is *almost* perfect in efficiency and precision, as all operations, except the cubic root operation, involve only double-word integers (i.e., less than $2^{31}$). In addition, a 32-bit integer's cubic root will have enough precision to get its accurate integer part.

All considered, this will be the way we calculate "the maximum number of visits you can pay before you run out of Gold" in our "convenience shop" extension function in `tswKai3`.
