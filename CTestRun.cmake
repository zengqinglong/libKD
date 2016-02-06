if(UNIX)
    if(DEFINED ENV{CC})
        string(SUBSTRING "$ENV{CC}" 0 3 CC)
        if(CC STREQUAL "gcc")
            set(CC_NAME "gcc")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
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
    endif()
else()
    set(CC_NAME "msvc")
    string(SUBSTRING $ENV{CMAKE_GENERATOR} 14 2 CC_VERSION)
    if($ENV{CMAKE_GENERATOR} MATCHES ".*ARM")
        set(CC_ARCH "arm")
    elseif($ENV{CMAKE_GENERATOR} MATCHES ".*Win64")
        set(CC_ARCH "x86_64")
    else()
        set(CC_ARCH "x86")
    endif()
endif()

if(DEFINED ENV{APPVEYOR})
    set(CI_NAME "Appveyor CI")
    string(SUBSTRING "$ENV{APPVEYOR_REPO_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-${CC_ARCH}-($ENV{APPVEYOR_BUILD_NUMBER})")
    set(CI_BUILD_DIR "$ENV{APPVEYOR_BUILD_FOLDER}")
elseif(DEFINED ENV{CIRCLECI})
    set(CI_NAME "Circle CI")
    string(SUBSTRING "$ENV{CIRCLE_SHA1}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{CIRCLE_BUILD_NUM})")
    set(CI_BUILD_DIR "$ENV{HOME}/libKD")
elseif(DEFINED ENV{GITLAB_CI})
    set(CI_NAME "GitLab CI")
    string(SUBSTRING "$ENV{CI_BUILD_REF}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-(-)")
    set(CI_BUILD_DIR "$ENV{CI_PROJECT_DIR}")
elseif(DEFINED ENV{MAGNUM})
    set(CI_NAME "Magnum CI")
    string(SUBSTRING "$ENV{CI_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{CI_BUILD_NUMBER})")
    set(CI_BUILD_DIR "$ENV{HOME}/libKD")
elseif(DEFINED ENV{SHIPPABLE})
    set(CI_NAME "Shippable CI")
    string(SUBSTRING "$ENV{COMMIT}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{SHIPPABLE_BUILD_NUMBER})")
    set(CI_BUILD_DIR "$ENV{SHIPPABLE_REPO_DIR}")
elseif(DEFINED ENV{TRAVIS})
    set(CI_NAME "Travis CI")
    string(SUBSTRING "$ENV{TRAVIS_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-($ENV{TRAVIS_BUILD_NUMBER})")
    set(CI_BUILD_DIR "$ENV{TRAVIS_BUILD_DIR}")
elseif(DEFINED ENV{WERCKER_ROOT})
    set(CI_NAME "Wercker CI")
    string(SUBSTRING "$ENV{WERCKER_GIT_COMMIT}" 0 8 CI_COMMIT_ID)
    set(CI_BUILD_NAME "${CI_COMMIT_ID}-${CC_NAME}-${CC_VERSION}-(-)")
    set(CI_BUILD_DIR "$ENV{WERCKER_ROOT}")
endif()

set(CTEST_SITE ${CI_NAME})
set(CTEST_BUILD_NAME ${CI_BUILD_NAME})

set(CTEST_SOURCE_DIRECTORY ${CI_BUILD_DIR})
set(CTEST_BINARY_DIRECTORY "${CTEST_SOURCE_DIRECTORY}/build")

if(DEFINED ENV{CMAKE_BUILD_TYPE})
    set(CTEST_BUILD_CONFIGURATION "$ENV{CMAKE_BUILD_TYPE}")
else()
    set(CTEST_BUILD_CONFIGURATION "Debug")
endif()
set(CTEST_CONFIGURATION_TYPE "${CTEST_BUILD_CONFIGURATION}")

if(UNIX)
    set(CTEST_CMAKE_GENERATOR "Unix Makefiles")

    find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
    set(CTEST_MEMORYCHECK_TYPE "Valgrind")
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--track-origins=yes --leak-check=yes")

    if(DEFINED ENV{CC})
        if(CC_NAME STREQUAL "gcc")
            string(SUBSTRING "$ENV{CC}" 4 -1 GCOV_VERSION)
            find_program(CTEST_COVERAGE_COMMAND NAMES gcov-${GCOV_VERSION})
        endif()
        if(CC_NAME STREQUAL "clang")
            string(SUBSTRING "$ENV{CC}" 6 -1 LLVMCOV_VERSION)
            find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov-${LLVMCOV_VERSION})
        endif()
    else()
        set(CTEST_COVERAGE_COMMAND "gcov")
    endif()
    set(CTEST_CUSTOM_COVERAGE_EXCLUDE ${CTEST_CUSTOM_COVERAGE_EXCLUDE} "/distribution/" "/examples/" "/thirdparty/" "/tests/" "/cov-int/" "/CMakeFiles/" "/usr/")
    set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} -l -p")
else()
    set(CTEST_CMAKE_GENERATOR "$ENV{CMAKE_GENERATOR}")
endif()

set(CTEST_TEST_TIMEOUT 30)

ctest_start(Continuous)
ctest_configure()
ctest_build()
ctest_test()
if(CTEST_MEMORYCHECK_COMMAND)
    ctest_memcheck()
endif()
if(CTEST_COVERAGE_COMMAND)
    ctest_coverage()
endif()
ctest_submit()