#include <iostream>
#include <cstdlib>

int add(int a, int b) {
    return a + b;
}

int multiply(int a, int b) {
    return a * b;
}

int main() {
    std::cout << "Running simple test..." << std::endl;
    
    int sum = add(2, 3);
    int product = multiply(4, 5);
    
    std::cout << "Sum: " << sum << std::endl;
    std::cout << "Product: " << product << std::endl;
    
    if (sum == 5 && product == 20) {
        std::cout << "Test PASSED" << std::endl;
        return EXIT_SUCCESS;
    } else {
        std::cout << "Test FAILED" << std::endl;
        return EXIT_FAILURE;
    }
}
