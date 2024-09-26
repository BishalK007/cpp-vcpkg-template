#include "math/math.h"

unsigned long long Math::factorial(int n) {
    // Check for negative numbers
    if (n < 0) {
        throw std::invalid_argument("Factorial is not defined for negative numbers.");
    }
    // Use Boost's factorial function (returns double)
    return static_cast<unsigned long long>(boost::math::factorial<double>(n));
}
