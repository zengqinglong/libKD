if(NOT DEFINED ENV{CI})
    message( FATAL_ERROR "Not a CI server." )
endif()

if(DEFINED ENV{CTEST_CMAKE_GENERATOR})
    set(CTEST_CMAKE_GENERATOR "$ENV{CTEST_CMAKE_GENERATOR}")
elseif(UNIX)
    set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
endif()

if(DEFINED ENV{CTEST_CONFIGURATION_TYPE})
    set(CTEST_CONFIGURATION_TYPE "$ENV{CTEST_CONFIGURATION_TYPE}")
else()
    set(CTEST_CONFIGURATION_TYPE "Debug")
endif()

# Compiler
if(UNIX)
    if(DEFINED ENV{CC})
        find_program(CC_FOUND NAMES $ENV{CC})
        if(NOT CC_FOUND)
            message( FATAL_ERROR "Compiler $ENV{CC} not found." )
        endif()
        string(SUBSTRING "$ENV{CC}" 0 3 CC)
        if(CC STREQUAL "gcc")
            set(CC_NAME "gcc")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
            if((CC_VERSION VERSION_GREATER 5) OR (CC_VERSION VERSION_EQUAL 5))
                string(SUBSTRING "${CC_VERSION}" 0 1 CC_VERSION)
            else()
                string(SUBSTRING "${CC_VERSION}" 0 3 CC_VERSION)
            endif()
        elseif(CC STREQUAL "icc")
            set(CC_NAME "icc")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
        endif()
        string(SUBSTRING "$ENV{CC}" 0 5 CC)
        if(CC STREQUAL "clang")
            if(APPLE)
                set(CC_NAME "xcode")
                exec_program(xcodebuild ARGS -version OUTPUT_VARIABLE CC_VERSION)
                string(REGEX REPLACE ".*Xcode ([0-9]+\\.[0-9]+).*" "\\1" CC_VERSION ${CC_VERSION})
            else()
                set(CC_NAME "clang")
                exec_program($ENV{CC} ARGS --version OUTPUT_VARIABLE CC_VERSION)
                string(REGEX REPLACE ".*clang version ([0-9]+\\.[0-9]+).*" "\\1" CC_VERSION ${CC_VERSION})
            endif()
        endif()
    else()
        set(CC_NAME "gcc")
        exec_program(${CC_NAME} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
        string(SUBSTRING "${CC_VERSION}" 0 3 CC_VERSION)
    endif()
else()
    set(CC_NAME "msvc")
    string(SUBSTRING ${CTEST_CMAKE_GENERATOR} 14 2 CC_VERSION)
    if(${CTEST_CMAKE_GENERATOR} MATCHES ".*ARM")
        set(CC_ARCH "arm")
    elseif(${CTEST_CMAKE_GENERATOR} MATCHES ".*Win64")
        set(CC_ARCH "x86_64")
    else()
        set(CC_ARCH "x86")
    endif()
endif()

# CI service
if(DEFINED ENV{APPVEYOR})
    set(CTEST_SITE "Appveyor CI")
    string(SUBSTRING "$ENV{APPVEYOR_REPO_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-${CC_ARCH}-($ENV{APPVEYOR_BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{APPVEYOR_BUILD_FOLDER}")
elseif(DEFINED ENV{CIRCLECI})
    set(CTEST_SITE "Circle CI")
    string(SUBSTRING "$ENV{CIRCLE_SHA1}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{CIRCLE_BUILD_NUM})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{HOME}/libKD")
elseif(DEFINED ENV{DRONE})
    set(CTEST_SITE "Drone CI")
    string(SUBSTRING "$ENV{DRONE_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{DRONE_BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{DRONE_BUILD_DIR}")
elseif(DEFINED ENV{GITLAB_CI})
    set(CTEST_SITE "GitLab CI")
    string(SUBSTRING "$ENV{CI_BUILD_REF}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-(-)")
    set(CTEST_SOURCE_DIRECTORY "$ENV{CI_PROJECT_DIR}")
elseif(DEFINED ENV{MAGNUM})
    set(CTEST_SITE "Magnum CI")
    string(SUBSTRING "$ENV{CI_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{CI_BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{HOME}/libKD")
elseif(DEFINED ENV{SEMAPHORE})
    set(CTEST_SITE "Semaphore CI")
    string(SUBSTRING "$ENV{REVISION}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{SEMAPHORE_BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{SEMAPHORE_PROJECT_DIR}")
elseif(DEFINED ENV{SHIPPABLE})
    set(CTEST_SITE "Shippable CI")
    string(SUBSTRING "$ENV{COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{SHIPPABLE_BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{SHIPPABLE_REPO_DIR}")
elseif(DEFINED ENV{SNAP_CI})
    set(CTEST_SITE "Snap CI")
    string(SUBSTRING "$ENV{SNAP_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{SNAP_PIPELINE_COUNTER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{SNAP_WORKING_DIR}")
elseif(DEFINED ENV{TRAVIS})
    set(CTEST_SITE "Travis CI")
    string(SUBSTRING "$ENV{TRAVIS_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{TRAVIS_BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{TRAVIS_BUILD_DIR}")
elseif(DEFINED ENV{WERCKER_ROOT})
    set(CTEST_SITE "Wercker CI")
    string(SUBSTRING "$ENV{WERCKER_GIT_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-(-)")
    set(CTEST_SOURCE_DIRECTORY "$ENV{WERCKER_ROOT}")
elseif(DEFINED ENV{GIT_COMMIT} AND DEFINED ENV{BUILD_NUMBER} AND DEFINED ENV{WORKSPACE})
    set(CTEST_SITE "Jenkins/Hudson CI")
    string(SUBSTRING "$ENV{GIT_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CTEST_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{BUILD_NUMBER})")
    set(CTEST_SOURCE_DIRECTORY "$ENV{WORKSPACE}")
endif()
set(CTEST_BINARY_DIRECTORY "${CTEST_SOURCE_DIRECTORY}/build")

ctest_start(Continuous)
ctest_configure()
ctest_build()
ctest_test()
ctest_submit(PARTS Configure Build Test)

# Coverage
set(CTEST_CUSTOM_COVERAGE_EXCLUDE ${CTEST_CUSTOM_COVERAGE_EXCLUDE} "/distribution/" "/examples/" "/thirdparty/" "/tests/" "/cov-int/" "/CMakeFiles/" "/usr/")
if(CC_NAME STREQUAL "gcc")
    find_program(CTEST_COVERAGE_COMMAND NAMES gcov-${CC_VERSION})
    if(NOT CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
    endif()
elseif(CC_NAME STREQUAL "clang")
    find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov-${CC_VERSION})
    if(NOT CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov)
    endif()
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} gcov")
    endif()
elseif(CC_NAME STREQUAL "xcode")
    find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov PATHS /Library/Developer/CommandLineTools/usr/bin/)
    if(CC_VERSION VERSION_GREATER 6.3 OR CC_VERSION VERSION_EQUAL 6.3)
        set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} gcov")
    endif()
elseif(CC_NAME STREQUAL "icc")
    find_program(CTEST_COVERAGE_COMMAND NAMES codecov)
endif()
if(CTEST_COVERAGE_COMMAND)
    if(CC_NAME STREQUAL "icc")
        set(CC_COVERAGE_FLAGS "${CC_COVERAGE_FLAGS} -prof-gen=srcpos")
    else()
        set(CC_COVERAGE_FLAGS "${CC_COVERAGE_FLAGS} --coverage")
    endif()
    ctest_configure(OPTIONS "-DKD_BUILD_CI_FLAGS=${CC_COVERAGE_FLAGS} -fno-omit-frame-pointer")
    ctest_build()
    ctest_test()
    ctest_coverage()
    ctest_submit(PARTS Coverage)
endif()

# Dynamic analysis (Valgrind)
find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
if(CTEST_MEMORYCHECK_COMMAND)
    set(CTEST_MEMORYCHECK_TYPE "Valgrind")
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --track-origins=yes --leak-check=full --show-reachable=yes")
    ctest_configure(OPTIONS "-DKD_BUILD_CI_FLAGS=-fno-omit-frame-pointer")
    ctest_build()
    ctest_memcheck(APPEND)
    ctest_submit(PARTS MemCheck)
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--tool=helgrind --read-var-info=yes")
    ctest_memcheck(APPEND)
    ctest_submit(PARTS MemCheck)
    set(CTEST_MEMORYCHECK_COMMAND "")
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "")
endif()

# Dynamic analysis (ASan)
# ASan was introduced in GCC 4.8 / Clang 3.1
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 4.8 OR CC_VERSION VERSION_EQUAL 4.8)
        set(CTEST_MEMORYCHECK_TYPE "AddressSanitizer")
    endif()
elseif(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.1 OR CC_VERSION VERSION_EQUAL 3.1)
        set(CTEST_MEMORYCHECK_TYPE "AddressSanitizer")
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "AddressSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1 check_initialization_order=1")
    ctest_configure(OPTIONS "-DKD_BUILD_CI_FLAGS=-fsanitize=address -fno-omit-frame-pointer")
    ctest_build()
    ctest_memcheck(APPEND)
    ctest_submit(PARTS MemCheck)
endif()

# Dynamic analysis (MSan)
# MSan was introduced in Clang 3.3
if(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.3 OR CC_VERSION VERSION_EQUAL 3.3)
        set(CTEST_MEMORYCHECK_TYPE "MemorySanitizer")
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "MemorySanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1")
    ctest_configure(OPTIONS "-DKD_BUILD_CI_FLAGS=-fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer")
    ctest_build()
    ctest_memcheck(APPEND)
    ctest_submit(PARTS MemCheck)
endif()

# Dynamic analysis(TSan)
# TSan was introduced in GCC 4.8 / Clang 3.2
# TSan works with non-pie builds starting GCC 5 / Clang 3.7
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 5 OR CC_VERSION VERSION_EQUAL 5)
        set(CTEST_MEMORYCHECK_TYPE "ThreadSanitizer")
        set(CC_TSAN_FLAGS "-static-libtsan")
    endif()
elseif(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        set(CTEST_MEMORYCHECK_TYPE "ThreadSanitizer")
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "ThreadSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1")
    ctest_configure(OPTIONS "-DKD_BUILD_CI_FLAGS=${CC_TSAN_FLAGS} -fsanitize=thread -fno-omit-frame-pointer")
    ctest_build()
    ctest_memcheck(APPEND)
    ctest_submit(PARTS MemCheck)
endif()

# Dynamic analysis (UBSan)
# UBan was introduced in GCC 4.9 / Clang 3.3
# UBSan respects log_path starting Clang 3.7
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 4.9 OR CC_VERSION VERSION_EQUAL 4.9)
        #set(CTEST_MEMORYCHECK_TYPE "UndefinedBehaviorSanitizer")
        set(CC_UBSAN_FLAGS "-fsanitize=adress,undefined")
    endif()
elseif(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        set(CTEST_MEMORYCHECK_TYPE "UndefinedBehaviorSanitizer")
        set(CC_UBSAN_FLAGS "-fsanitize=adress,undefined,integer -fno-sanitize=vptr -fno-sanitize-recover")
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "UndefinedBehaviorSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1 print_stacktrace=1")
    ctest_configure(OPTIONS "-DKD_BUILD_CI_FLAGS=${CC_UBSAN_FLAGS}-fno-omit-frame-pointer")
    ctest_build()
    ctest_memcheck(APPEND)
    ctest_submit(PARTS MemCheck)
endif()