# This file defines mathematical tables for common functions.
# Now Returns multiplication table instead of printing it

def get_multiplication_table(number):
    """Returns the multiplication table lines for a number."""
    table = []
    for i in range(1, 11):
        table.append(f"{number} x {i} = {number * i}")
    return table
