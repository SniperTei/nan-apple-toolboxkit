#include "mn_logger_core.h"
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>

// 日志缓冲项结构
typedef struct {
    MNLogLevel level;
    char* message;
    char* file;
    char* function;
    int line;
    time_t timestamp;
} LogEntry;

// 全局日志系统状态
static struct {
    FILE* log_file;
    LogEntry* buffer;
    uint32_t buffer_size;
    uint32_t buffer_count;
    pthread_mutex_t buffer_mutex;
    pthread_cond_t buffer_cond;
    pthread_t writer_thread;
    bool running;
    MNLogLevel min_level;
} g_log_state;

// 写入线程函数
static void* writer_thread_func(void* arg) {
    while (g_log_state.running) {
        pthread_mutex_lock(&g_log_state.buffer_mutex);
        
        // 如果缓冲区为空，等待新条目或关闭信号
        while (g_log_state.buffer_count == 0 && g_log_state.running) {
            pthread_cond_wait(&g_log_state.buffer_cond, &g_log_state.buffer_mutex);
        }
        
        // 如果系统正在关闭且缓冲区为空，退出循环
        if (!g_log_state.running && g_log_state.buffer_count == 0) {
            pthread_mutex_unlock(&g_log_state.buffer_mutex);
            break;
        }
        
        // 批量写入所有缓冲的条目
        for (uint32_t i = 0; i < g_log_state.buffer_count; i++) {
            LogEntry* entry = &g_log_state.buffer[i];
            
            // 检查日志级别
            if (entry->level >= g_log_state.min_level) {
                // 格式化时间
                char time_str[32];
                struct tm* timeinfo = localtime(&entry->timestamp);
                strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", timeinfo);
                
                // 获取日志级别字符串
                const char* level_str = "UNKNOWN";
                switch (entry->level) {
                    case MN_LOG_LEVEL_DEBUG: level_str = "DEBUG";
                        break;
                    case MN_LOG_LEVEL_INFO: level_str = "INFO";
                        break;
                    case MN_LOG_LEVEL_WARNING: level_str = "WARNING";
                        break;
                    case MN_LOG_LEVEL_ERROR: level_str = "ERROR";
                        break;
                    case MN_LOG_LEVEL_FATAL: level_str = "FATAL";  // 将 CRITICAL 改为 FATAL
                        break;
                }
                
                // 写入日志到文件
                fprintf(g_log_state.log_file, "[%s] [%s] %s (at %s:%s:%d)\n", 
                        time_str, level_str, entry->message, entry->file, entry->function, entry->line);
            }
            
            // 释放内存
            free(entry->message);
            free(entry->file);
            free(entry->function);
        }
        
        // 清空缓冲区
        g_log_state.buffer_count = 0;
        
        // 通知等待的生产者线程
        pthread_cond_broadcast(&g_log_state.buffer_cond);
        pthread_mutex_unlock(&g_log_state.buffer_mutex);
        
        // 刷新文件缓冲区，确保日志内容可靠
        fflush(g_log_state.log_file);
        
        // 短暂休眠，避免CPU占用过高
        usleep(1000); // 1ms
    }
    
    return NULL;
}

// 初始化日志系统
void mn_logger_init(const char* log_file_path, uint32_t buffer_size) {
    // 初始化全局状态
    memset(&g_log_state, 0, sizeof(g_log_state));
    
    // 打开日志文件
    g_log_state.log_file = fopen(log_file_path, "a");
    if (!g_log_state.log_file) {
        // 如果无法打开文件，使用标准错误输出
        g_log_state.log_file = stderr;
    }
    
    // 分配缓冲区
    g_log_state.buffer_size = buffer_size > 0 ? buffer_size : 1000;
    g_log_state.buffer = (LogEntry*)malloc(sizeof(LogEntry) * g_log_state.buffer_size);
    if (!g_log_state.buffer) {
        g_log_state.buffer_size = 0;
    }
    
    // 初始化互斥锁和条件变量
    pthread_mutex_init(&g_log_state.buffer_mutex, NULL);
    pthread_cond_init(&g_log_state.buffer_cond, NULL);
    
    // 设置默认日志级别
    g_log_state.min_level = MN_LOG_LEVEL_DEBUG;
    g_log_state.running = true;
    
    // 创建写入线程
    pthread_create(&g_log_state.writer_thread, NULL, writer_thread_func, NULL);
}

// 记录日志
void mn_logger_write(MNLogLevel level, const char* message, const char* file, const char* function, int line) {
    // 如果没有初始化，直接返回
    if (!g_log_state.running || !message) {
        return;
    }
    
    pthread_mutex_lock(&g_log_state.buffer_mutex);
    
    // 如果缓冲区已满，等待写入线程处理一些条目
    while (g_log_state.buffer_count >= g_log_state.buffer_size) {
        pthread_cond_wait(&g_log_state.buffer_cond, &g_log_state.buffer_mutex);
        
        // 如果系统正在关闭，直接返回
        if (!g_log_state.running) {
            pthread_mutex_unlock(&g_log_state.buffer_mutex);
            return;
        }
    }
    
    // 创建新的日志条目
    LogEntry* entry = &g_log_state.buffer[g_log_state.buffer_count];
    entry->level = level;
    entry->message = strdup(message);
    entry->file = file ? strdup(file) : strdup("unknown");
    entry->function = function ? strdup(function) : strdup("unknown");
    entry->line = line;
    entry->timestamp = time(NULL);
    
    g_log_state.buffer_count++;
    
    // 通知写入线程有新条目
    pthread_cond_signal(&g_log_state.buffer_cond);
    pthread_mutex_unlock(&g_log_state.buffer_mutex);
}

// 设置最小日志级别
void mn_logger_set_min_level(MNLogLevel level) {
    pthread_mutex_lock(&g_log_state.buffer_mutex);
    g_log_state.min_level = level;
    pthread_mutex_unlock(&g_log_state.buffer_mutex);
}

// 刷新日志缓冲区
void mn_logger_flush(void) {
    pthread_mutex_lock(&g_log_state.buffer_mutex);
    
    // 如果缓冲区不为空，通知写入线程
    if (g_log_state.buffer_count > 0) {
        pthread_cond_signal(&g_log_state.buffer_cond);
    }
    
    pthread_mutex_unlock(&g_log_state.buffer_mutex);
    
    // 短暂等待，给写入线程时间处理
    usleep(10000); // 10ms
}

// 关闭日志系统
void mn_logger_close(void) {
    pthread_mutex_lock(&g_log_state.buffer_mutex);
    g_log_state.running = false;
    pthread_cond_signal(&g_log_state.buffer_cond);
    pthread_mutex_unlock(&g_log_state.buffer_mutex);
    
    // 等待写入线程结束
    pthread_join(g_log_state.writer_thread, NULL);
    
    // 清理资源
    if (g_log_state.log_file && g_log_state.log_file != stderr) {
        fclose(g_log_state.log_file);
    }
    
    if (g_log_state.buffer) {
        free(g_log_state.buffer);
    }
    
    pthread_mutex_destroy(&g_log_state.buffer_mutex);
    pthread_cond_destroy(&g_log_state.buffer_cond);
}