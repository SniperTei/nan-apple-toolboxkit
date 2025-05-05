#include "snp_log_writer.h"
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

#define BUFFER_SIZE (64 * 1024)  // 64KB buffer

struct Logger {
    int fd;                     // 文件描述符
    char* buffer;               // 写入缓冲区
    size_t buffer_used;         // 已使用的缓冲区大小
    pthread_mutex_t mutex;      // 互斥锁
    char* path;                 // 文件路径
};

void* snp_log_create(const char* path) {
    if (!path) return NULL;
    
    // 分配Logger结构体
    struct Logger* logger = (struct Logger*)calloc(1, sizeof(struct Logger));
    if (!logger) return NULL;
    
    // 复制文件路径
    logger->path = strdup(path);
    if (!logger->path) {
        free(logger);
        return NULL;
    }
    
    // 分配缓冲区
    logger->buffer = (char*)malloc(BUFFER_SIZE);
    if (!logger->buffer) {
        free(logger->path);
        free(logger);
        return NULL;
    }
    
    // 初始化互斥锁
    if (pthread_mutex_init(&logger->mutex, NULL) != 0) {
        free(logger->buffer);
        free(logger->path);
        free(logger);
        return NULL;
    }
    
    // 打开或创建日志文件
    logger->fd = open(path, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (logger->fd == -1) {
        pthread_mutex_destroy(&logger->mutex);
        free(logger->buffer);
        free(logger->path);
        free(logger);
        return NULL;
    }
    
    logger->buffer_used = 0;
    return logger;
}

int snp_log_write(void* handle, const char* content, size_t length) {
    struct Logger* logger = (struct Logger*)handle;
    if (!logger || !content || !length) return -1;
    
    int result = 0;
    pthread_mutex_lock(&logger->mutex);
    
    // 如果缓冲区满了，先刷新
    if (logger->buffer_used + length > BUFFER_SIZE) {
        ssize_t written = write(logger->fd, logger->buffer, logger->buffer_used);
        if (written != logger->buffer_used) {
            result = -1;
        }
        logger->buffer_used = 0;
    }
    
    // 如果日志内容大于缓冲区，直接写入
    if (length > BUFFER_SIZE) {
        ssize_t written = write(logger->fd, content, length);
        if (written != length) {
            result = -1;
        }
    } else {
        // 复制到缓冲区
        memcpy(logger->buffer + logger->buffer_used, content, length);
        logger->buffer_used += length;
    }
    
    pthread_mutex_unlock(&logger->mutex);
    return result;
}

void snp_log_flush(void* handle) {
    struct Logger* logger = (struct Logger*)handle;
    if (!logger) return;
    
    pthread_mutex_lock(&logger->mutex);
    
    if (logger->buffer_used > 0) {
        write(logger->fd, logger->buffer, logger->buffer_used);
        logger->buffer_used = 0;
        fsync(logger->fd);  // 确保写入磁盘
    }
    
    pthread_mutex_unlock(&logger->mutex);
}

void snp_log_destroy(void* handle) {
    struct Logger* logger = (struct Logger*)handle;
    if (!logger) return;
    
    // 刷新剩余的日志
    snp_log_flush(logger);
    
    // 关闭文件
    close(logger->fd);
    
    // 清理资源
    pthread_mutex_destroy(&logger->mutex);
    free(logger->buffer);
    free(logger->path);
    free(logger);
} 