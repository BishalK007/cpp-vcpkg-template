#include "utils/utils.h"
#include <fmt/core.h>

// Implementation of the formatGreeting function
std::string formatGreeting(const std::string& name) {
    return fmt::format("Hello, {}! Welcome to our program.", name);
}
