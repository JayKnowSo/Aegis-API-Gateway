# Month 3 - Input Validation helper functions

def get_nonempty_name():
    """Prompt the user for a non-empty name."""
    while True:
        username = input("Enter your username:").strip()
        if username == "":
            print("Username cannot be empty. Please enter a valid username.")
        else:
            return username # Exits loop when valid

def get_positive_number(prompt): # May raise ValueError
    while True:
        try:
            number = int(input(prompt))
        except ValueError:
            print("Invalid input. Please enter a valid number.")
        else: # runs only if try block is successful
             if number <= 0:
                print("Please enter a number greater than 0.")
             else: # Only runs if number is valid
                 return number # Exits loop properly

def get_yes_no(prompt):
    """Prompt the user for a 'yes' or 'no' answer."""
    while True:
        answer = input(prompt).strip().lower()
        if answer in ["yes", "no"]:
            return answer # Exits loop when valid
        else:
            print("Please enter 'yes' or 'no'.")
