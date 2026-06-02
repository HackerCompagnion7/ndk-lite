#pragma once

#include <string>

namespace assimp_lite {

// Log severity levels
enum class log_level {
    verbose = 0,
    info    = 1,
    warning = 2,
    error   = 3,
    none    = 4   // disables all logging
};

// Set the global log level; messages below this level are suppressed
void set_log_level(log_level level);

// Get the current log level
log_level get_log_level();

// Logging functions at each severity level
void log_verbose(const std::string& message);
void log_info(const std::string& message);
void log_warning(const std::string& message);
void log_error(const std::string& message);

} // namespace assimp_lite
