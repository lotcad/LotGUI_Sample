function(lotgui_compile_options target)
    target_compile_features(${target} PRIVATE cxx_std_17)
    if(MSVC)
        target_compile_options(${target} PRIVATE /W4 /permissive- /utf-8)
    else()
        target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic)
    endif()
endfunction()
function(lotgui_stage_resources target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E make_directory
            "$<TARGET_FILE_DIR:${target}>/resources/fonts" "$<TARGET_FILE_DIR:${target}>/legal"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${LOTGUI_FONT_FILE}" "$<TARGET_FILE_DIR:${target}>/resources/fonts/NotoSansKR-Regular.ttf"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE" "$<TARGET_FILE_DIR:${target}>/legal/LICENSE"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/THIRD_PARTY_NOTICES.md" "$<TARGET_FILE_DIR:${target}>/legal/THIRD_PARTY_NOTICES.md"
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${CMAKE_CURRENT_SOURCE_DIR}/licenses" "$<TARGET_FILE_DIR:${target}>/legal/licenses"
        VERBATIM)
endfunction()
