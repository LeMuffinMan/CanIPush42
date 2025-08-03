#!/bin/bash

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

relink()
{
  OUTPUT=$(make)

  if echo "$OUTPUT" | grep -q "make: Nothing to be done for 'all'." > /dev/null ; then
    echo -e "${RED}KO${NC}"
    ((ERRORS++))
    return 1
  else
    echo -e "${GREEN}OK${NC}"
    return 0
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
