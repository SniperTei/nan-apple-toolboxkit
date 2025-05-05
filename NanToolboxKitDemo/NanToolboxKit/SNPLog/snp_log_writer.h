#ifndef snp_log_writer_h
#define snp_log_writer_h

#include <stdio.h>
#include <stdint.h>
#include <pthread.h>
#include <sys/types.h>

// 创建日志写入器
void* snp_log_create(const char* path);

// 写入日志
int snp_log_write(void* logger, const char* content, size_t length);

// 刷新缓冲区
void snp_log_flush(void* logger);

// 关闭并释放日志写入器
void snp_log_destroy(void* logger);

#endif /* snp_log_writer_h */ 