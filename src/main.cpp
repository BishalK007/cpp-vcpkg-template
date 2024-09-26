#include <iostream>
#include "utils/utils.h"
#include "math/math.h"

int main() {
    std::string name = "Bob";  // You can change this to test with different names
    std::string greeting = formatGreeting(name); // Call the utility function
    std::cout << greeting << std::endl; // Output the formatted greeting

    int number;

    std::cout << "Enter a non-negative integer to compute its factorial: ";
    std::cin >> number;

    try {
        unsigned long long result = Math::factorial(number);
        std::cout << "Factorial of " << number << " is " << result << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }

    return 0;
}
