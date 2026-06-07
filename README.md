# Stack-Based Expression Evaluator

An Assembly Language project that evaluates mathematical expressions using a stack-based approach.

## Features

- Stack implementation using Assembly Language
- Expression evaluation
- Supports arithmetic operations
- Demonstrates stack manipulation and expression processing concepts

## Technologies Used

- Assembly Language
- Visual Studio
- MASM (if applicable)

## How to Run

1. Open the project in Visual Studio.
2. Build the project.
3. Run the executable.
4. Enter the expression as required by the program.

## Project Purpose

This project was developed for our COAL Course, to demonstrate the use of stacks in Assembly Language for evaluating expressions and performing arithmetic computations.

## Author

Mohsin Ali

After creating README.md, run:

git add README.md
git commit -m "Added README"
git push

If your evaluator supports specific things (e.g., infix-to-postfix conversion, parentheses, multi-digit numbers, etc.), I can make the README more professional and tailored to the actual project.

yes it does this all

Then a slightly more professional README would be:

# Stack-Based Expression Evaluator

A Stack-Based Expression Evaluator developed in Assembly Language. The program uses stack data structures to process and evaluate mathematical expressions by converting infix expressions into postfix notation and then computing the final result.

## Features

- Infix to Postfix conversion
- Postfix expression evaluation
- Support for arithmetic operators:
  - Addition (+)
  - Subtraction (-)
  - Multiplication (*)
  - Division (/)
- Parentheses handling
- Multi-digit number support
- Stack implementation in Assembly Language
- Error handling for invalid expressions

## How It Works

1. The user enters an infix expression.
2. The program converts the infix expression to postfix notation using a stack.
3. The postfix expression is evaluated using another stack.
4. The final result is displayed to the user.

## Example

### Input

```text
(12 + 8) * 3
Postfix Conversion
12 8 + 3 *
Output
60
Technologies Used
Assembly Language
MASM
Visual Studio
Learning Objectives

This project demonstrates:

Stack data structures
Expression parsing
Infix-to-postfix conversion algorithms
Postfix evaluation algorithms
Assembly Language programming concepts
Author

Mohsin Ali & Team 

Course Instructor
Mr. Qaiser Manzoor
