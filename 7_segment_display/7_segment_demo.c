#define SegEn_ADDR    0x80001038
#define SegDig_ADDR   0x8000103C

#define WRITE_7Seg(dir, value) { (*(volatile unsigned *)dir) = (value); }

#define N 8

int main ( void )
{
    WRITE_7Seg(SegEn_ADDR, 0x00);
    WRITE_7Seg(SegDig_ADDR, 18306749);   //hello
    WRITE_7Seg(SegDig_ADDR, 6073113);    //start
    WRITE_7Seg(SegDig_ADDR, 176470);     //scan 
    WRITE_7Seg(SegDig_ADDR, 31393725);   //0-100
    WRITE_7Seg(SegDig_ADDR, 73336765);   //25-100
    WRITE_7Seg(SegDig_ADDR, 199165885);  //50-100
    WRITE_7Seg(SegDig_ADDR, 241108925);  //75-100
    WRITE_7Seg(SegDig_ADDR, 2078214077); //100-100
    WRITE_7Seg(SegDig_ADDR, 15414733);   //ended

    while (1);

    return(0);
}
