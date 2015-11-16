SET(NEMO_INSTALLED FALSE)

FILE(GLOB GLOB_TEMP_VAR $ENV{NEMO})
IF(GLOB_TEMP_VAR)
  SET(NEMO_INSTALLED TRUE)
ENDIF(GLOB_TEMP_VAR)

if (NOT NEMO_INSTALLED)
MESSAGE(SEND_ERROR "NEMO environement not loaded, cannot continue....")
endif (NOT NEMO_INSTALLED)