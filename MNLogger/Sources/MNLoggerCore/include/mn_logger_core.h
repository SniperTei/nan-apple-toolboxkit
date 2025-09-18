#ifndef MN_LOGGER_CORE_H
#define MN_LOGGER_CORE_H

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <time.h>

// 日志级别定义
typedef enum {
    MN_LOG_LEVEL_DEBUG = 0,
    MN_LOG_LEVEL_INFO = 1,
    MN_LOG_LEVEL_WARNING = 2,
    MN_LOG_LEVEL_ERROR = 3,
    MN_LOG_LEVEL_FATAL = 4  // 将 CRITICAL 改为 FATAL
} MNLogLevel;

// 初始化日志系统
void mn_logger_init(const char* log_file_path, uint32_t buffer_size);

// 记录日志
void mn_logger_write(MNLogLevel level, const char* message, const char* file, const char* function, int line);

// 设置最小日志级别
void mn_logger_set_min_level(MNLogLevel level);

// 刷新日志缓冲区
void mn_logger_flush(void);

// 关闭日志系统
void mn_logger_close(void);

#endif /* MN_LOGGER_CORE_H */