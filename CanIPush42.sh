#!/bin/bash

set -euo pipefail

MAKEFILE_CONTENT=$(<Makefile)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 
ERRORS=0

check_flags()
{
  for flag in "-Wextra" "-Werror" "-Wall"; do
    if ! echo "$MAKEFILE_CONTENT" | grep -q -- "$flag"; then
      echo -e "${RED}KO${NC}"
      ((ERRORS++))
      return 1
    fi
  done
  echo -e "${GREEN}OK${NC}"
}

compile()
{
  OUTPUT=$(make 2>&1)
  STATUS=$?

  if [[ $STATUS -ne 0 ]]; then
    echo -e "${RED}KO${NC}"
      ((ERRORS++))
      return 1
  else
    if echo "$OUTPUT" | grep -qEi 'warning:|error:|undefined reference|missing separator|No rule to make target|warning: overriding recipe ' > /dev/null; then
      echo -e "${RED}KO${NC}"
      ((ERRORS++))
      return 1
    else
      echo -e "${GREEN}OK${NC}"
      return 0
    fi
  fi
}

check_phony()
{
  if ! grep -q '^\.PHONY:' Makefile; then
    echo ".PHONY absent"
    return 1
  fi

  PHONY_TARGETS=$(grep '^\.PHONY:' Makefile | sed 's/^\.PHONY:[[:space:]]*//')

  local missing=0
  for target in all clean fclean re; do
    if ! echo "$PHONY_TARGETS" | grep -qw "$target"; then
      echo "La cible '$target' n'est pas déclarée dans .PHONY"
      missing=1
    fi
  done

  if [[ $missing -eq 0 ]]; then
    echo -e "${GREEN}OK${NC}"
    return 0
  else
    return 1
  fi
}

echo -n "Compilations flag    : "
check_flags
if [[ "${1:-}" == "--cpp" ]]; then
  echo -n "c++98 flag           : "
  if grep -q -- "-std=c++98" Makefile; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}KO${NC}"
    ((ERRORS++))
  fi
# else
  # echo -n "Norminette : "
  #
fi


echo -n "Wildcards            : "
if ! echo "$MAKEFILE_CONTENT" | grep -qE '\*\.c|\*\.cpp|\*\.o|wildcard'; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}KO${NC}"
  ((ERRORS++))
fi

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


echo -n ".PHONY               : "
check_phony


FIRST_RULE=$(grep -E '^[[:space:]]*[a-zA-Z0-9_.-]+:' Makefile | grep -v '^\.PHONY:' | head -n 1 | cut -d':' -f1)

echo -n "Default rule check   : "
if [[ "$FIRST_RULE" == "all" ]]; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}KO${NC}"
  ((ERRORS++))
fi

echo -n "Compilation test     : "
make fclean > /dev/null 2>&1
compile
make fclean > /dev/null 2>&1
FILES=(include/*)
RANDOM_FILE=${FILES[RANDOM % ${#FILES[@]}]}
echo -n "Relink on $RANDOM_FILE : "
touch "$RANDOM_FILE"
compile
make fclean > /dev/null 2>&1
FILES=(src/*)
RANDOM_FILE=${FILES[RANDOM % ${#FILES[@]}]}
echo -n "Relink on $RANDOM_FILE : "
touch "$RANDOM_FILE"
compile
make fclean > /dev/null 2>&1
echo -n "Relink on Makefile : "
touch Makefile
compile
make fclean > /dev/null 2>&1

# chercher le binaire
# chercher des .o
# chercher des fichiers a la racine 
# chercher src, include, Makefile

if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}Ready to push !${NC}"
fi
