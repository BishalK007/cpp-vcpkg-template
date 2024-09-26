#ifndef MATH_H
#define MATH_H

#include <boost/math/special_functions/factorials.hpp>
#include <stdexcept> // For std::invalid_argument

class Math {
public:
    // Static method for factorial calculation
    static unsigned long long factorial(int n);
};

#endif // MATH_H
