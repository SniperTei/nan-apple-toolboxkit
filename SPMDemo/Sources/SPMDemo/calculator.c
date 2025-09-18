#include "calculator.h"

// 加法函数实现
double addC(double a, double b) {
    return a + b;
}

// 减法函数实现
double subtractC(double a, double b) {
    return a - b;
}

// 乘法函数实现
double multiplyC(double a, double b) {
    return a * b;
}

// 除法函数实现
double divideC(double a, double b) {
    // 简单的除零检查
    if (b == 0) {
        // 在实际应用中可能需要更完善的错误处理
        return 0;
    }
    return a / b;
}