#!/bin/bash

# Stop the script if any command fails, if using undefined variables, or on pipe errors
# set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 

MAKEFILE_CONTENT=$(<Makefile)
ERRORS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
# compile(), relink(), check_flags() check_phony()

if [[ -z "Makefile" ]]; then
  echo "No Makefile found"
  return 1
fi

echo -n "Compilations flag    : "
check_flags

# If script called with --cpp argument, check for C++98 flag in Makefile
# By default, search for -Werror -Wextra -Wall, and execute norminette on src/* and include/*
if [[ "${1:-}" == "--cpp" ]]; then
  echo -n "c++98 flag           : "
  if grep -q -- "-std=c++98" Makefile; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}KO${NC}"
    ((ERRORS++))
  fi
# else
# norminette
fi

# Seeks any *.c / wildcards ...
echo -n "Wildcards            : "
if ! echo "$MAKEFILE_CONTENT" | grep -qE '\*\.c|\*\.cpp|\*\.o|wildcard'; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}KO${NC}"
  ((ERRORS++))
fi

# Norm v4 ask for specific minimal rules for Makefile 
echo -n "Makefile rules       : "
if echo "$MAKEFILE_CONTENT" | grep -qF "all:" &&
   echo "$MAKEFILE_CONTENT" | grep -qF "\$(NAME):" &&
   echo "$MAKEFILE_CONTENT" | grep -qF "re:" &&
   echo "$MAKEFILE_CONTENT" | grep -qF "clean:" &&
   echo "$MAKEFILE_CONTENT" | grep -qF "fclean:"; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}KO${NC}"
  ((ERRORS++))
fi

# Checks only for required rules : all clean fclean re
echo -n ".PHONY               : "
check_phony

FIRST_RULE=$(grep -E '^[[:space:]]*[a-zA-Z0-9_.-]+:' Makefile | grep -v '^\.PHONY:' | head -n 1 | cut -d':' -f1)

# Norm v4 require all to be the first dans default rule
echo -n "Default rule check   : "
if [[ "$FIRST_RULE" == "all" ]]; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}KO${NC}"
  ((ERRORS++))
fi

# Theses tests assume your clean and fclean rules work fine
echo -n "Compilation test     : "
make fclean > /dev/null 2>&1
compile

# Pick a random header file and test relink after modifying it
FILES=(include/*)
RANDOM_FILE=${FILES[RANDOM % ${#FILES[@]}]}
echo -n "Relink on $RANDOM_FILE : "
touch "$RANDOM_FILE"         
relink

make fclean > /dev/null 2>&1
# Pick a random source file and test relink after modifying it
FILES=(src/*)
RANDOM_FILE=${FILES[RANDOM % ${#FILES[@]}]}
echo -n "Relink on $RANDOM_FILE : "
make > /dev/null 2>&1       
touch "$RANDOM_FILE"        
relink                      

make fclean > /dev/null 2>&1
# Test relink after modifying Makefile
echo -n "Relink on Makefile : "
make > /dev/null 2>&1      
touch Makefile              
relink

make fclean > /dev/null 2>&1

# - Check for binary 
# - Check for object files (.o)

if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}Ready to push !${NC}"
fi

