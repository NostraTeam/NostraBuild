
#include "nostra/testproject/component.hpp"

namespace ntp
{
    int test2();
}

int main()
{
    ntp::test2(); /* from source.c */
    ntp::test();  /* from nostra/testproject/component.h */

    return 0;
}