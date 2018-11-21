
#include "nostra/testproject/component.h"

extern int test2();

int main()
{
    test2();
    test(); /* from nostra/testproject/component.h */

    return 0;
}