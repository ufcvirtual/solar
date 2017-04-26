var dropdown_open = false;

function dropdownIsOpen() {
  return dropdown_open;
}

function openDropdown() {
  dropdown_open = true;
}

function closeDropdown() {
  dropdown_open = false;
}

function toggleDropdown() {
  dropdown_open = !dropdown_open;
}
