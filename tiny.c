int abc;

// dont check at top, check as soon as return statement is seen!
int gcd (int u, int v)
 { if (v == 0) return u;
    else return gcd(v, u-u/v*v);
    /* dfkljdf */
 }
 
 void main(void)
 {    int x; int y;
    x = gcd(x, y); y = gcd(y, y);
    gcd(gcd(x, y), y);
 }
int main2(void test, int test2[]) {
  int q[12];
  return q[1];
}
float main3(void)
{
  int x;
  int y;
  int z;
  float m;
  float p;

  if (m == z) {
    main3();
  }
   while(x+3 > 5)
   {
     main3();
     x = y + y / z;
     m = m -p;
   }
   return m;
}
int sub(int x)
{
   return(x+x);
}
int main4(int z)
{
  int x;
  int y;
  y = sub(x);
   return(x+x);
}
