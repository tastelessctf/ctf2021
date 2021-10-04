#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <string.h>
#include <string>
#include <iostream>
#include <exception>
#include <sstream>
#include <map>
#include <limits>
#include <alloca.h>
#include "Exceptions.hpp"
#include "Colors.hpp"
#include "chall.hpp"

#define DEBUG
using namespace std;

ReleasedChallenge::ReleasedChallenge():
    points(0), solved(false)
{
    set_points();
    set_flag();
}

ReleasedChallenge::ReleasedChallenge(Challenge* uc): Challenge(uc->name) {
    if (dynamic_cast<UnreleasedChallenge *>(uc) == NULL) {
        throw new AlreadyReleasedChallengeException(uc);
    }

    set_points();
    set_flag();
}

void ReleasedChallenge::set_points() {
    cout << "How many points should this challenge have?" << endl;
    if (!(cin >> points)) {
        cin.clear();
        cin.ignore();
        throw new InvalidInputException();
    }
}

void ReleasedChallenge::set_flag() {
    string _flag;
    cout << "What should the flag be?" << endl;
    cin >> _flag;
    if (_flag.rfind("flag{", 0) != 0)
        throw new InvalidInputException();
    if (_flag.back() != '}')
        throw new InvalidInputException();
    flag = _flag;
}

string read_multiline() {
    stringstream ss;
    string line, output;
    cout << "Terminate input with a . on a single line" << endl;
    while (true) {
        getline(cin, line);
        if (!line.compare("."))
            break;
        ss << line << endl;
    };
    output = ss.str();
    if (!output.length()) {
        throw new InvalidInputException();
    }
    return output;
};

BrokenChallenge::BrokenChallenge(Challenge* uc): Challenge(uc->name) {
    if (dynamic_cast<BrokenChallenge *>(uc)) {
        throw new AlreadyBrokenChallengeException(uc);
    }
    cout << "Enter the reason why this challenge is borken. ";
    reason = read_multiline();
}

Challenge::Challenge()
{
    string _name;
    cout << "What do you want to call your challenge?" << endl
            << "House of " << flush;
    cin >> _name;
    stringstream ss;
    ss << "House of " << _name;
    name = ss.str();
}

int ReleasedChallenge::solve() {
    if (solved) {
        throw new AlreadySolvedException(name);
    }

    bool correct = check_flag(flag.c_str(), flag.length());

    if (correct) {
        cout << GREEN << "CONGRATS! YOU WIN " << points << " POINTS!" << RESET << endl;
        solved = true;
        return points;
    }

    throw new InvalidFlagException();
}

void CTF::play() {
    while (true) {
        try {
            if (menu())
                break;
        }
        catch (NonFatalException *e) {
            cout << RED << "Error: " << e->what() << RESET << endl;
            delete e;
        }
    }
}

void CTF::list() {
    if (challenges.empty()) {
        throw new NoChallengesYetException();
    }

    map<string, Challenge*>::iterator it = challenges.begin();
    while(it != challenges.end()) {
        if (ReleasedChallenge * rc = dynamic_cast<ReleasedChallenge*>(it->second))
            cout << *rc << endl;
        else if (BrokenChallenge *bc = dynamic_cast<BrokenChallenge*>(it->second))
            cout << *bc << endl;
        else if (UnreleasedChallenge *uc = dynamic_cast<UnreleasedChallenge*>(it->second))
            cout << *uc << endl;
        it++;
    }
}

void CTF::make_chall() {
    UnreleasedChallenge *new_challenge = NULL;

    new_challenge = new UnreleasedChallenge();

    try {
        challenges.at(new_challenge->name);
    }
    catch (out_of_range &e) {
        challenges[new_challenge->name] = new_challenge;
        return;
    }

    throw new DuplicateNameException(new_challenge->name);
    delete new_challenge;
}

void CTF::release_chall() {
    struct {
        ReleasedChallenge *rc;
        Challenge *challenge;
        string challenge_name;
    } stack = { 0 };

    cout << "What challenge?" << endl;
    getline(cin, stack.challenge_name);
    try {
        stack.challenge = challenges.at(stack.challenge_name);
    }
    catch (out_of_range &e) {
        throw new NoSuchChallengeException(stack.challenge_name);
    }

    if (dynamic_cast<BrokenChallenge*>(stack.challenge)) {
        throw new BrokenChallengeException(stack.challenge_name);
    }

    while (true) {
        try {
            stack.rc = new ReleasedChallenge(stack.challenge);
        }
        catch (InvalidInputException *e) {
            cout << "Error releasing challenge " << stack.challenge << ", try again." << endl;
            continue;
        }
        break;
    }

    challenges[stack.challenge_name] = stack.rc;
    delete stack.challenge;
}

void CTF::break_chall() {
    struct {
        BrokenChallenge *bc;
        Challenge *challenge;
        string challenge_name;
    } stack = { 0 };

    cout << "What challenge?" << endl;
    getline(cin, stack.challenge_name);

    try {
        stack.challenge = challenges.at(stack.challenge_name);
    }
    catch (out_of_range &e) {
        throw new NoSuchChallengeException(stack.challenge_name);
    }

    while (true) {
        try {
            stack.bc = new BrokenChallenge(stack.challenge);
        }
        catch (InvalidInputException *e) {
            cout << "Error releasing challenge " << stack.challenge << ", try again." << endl;
            continue;
        }
        break;
    }

    challenges[stack.challenge_name] = stack.bc;
    delete stack.challenge;
}

void CTF::solve_chall() {
    struct {
        ReleasedChallenge *rc;
        Challenge *challenge;
        string challenge_name;
    } stack = { 0 };

    cout << "What challenge?" << endl;
    getline(cin, stack.challenge_name);

    try {
        stack.challenge = challenges.at(stack.challenge_name);
    }
    catch (out_of_range &e) {
        throw new NoSuchChallengeException(stack.challenge_name);
    }

    if (dynamic_cast<BrokenChallenge*>(stack.challenge)) {
        throw new BrokenChallengeException(stack.challenge->name);
    }

    stack.rc = dynamic_cast<ReleasedChallenge*>(stack.challenge);
    if (!stack.rc) {
        throw new UnreleasedChallengeException();
    }
    points += stack.rc->solve();
}

bool CTF::menu() {
    long choice = 0;
    string challenge_name;
    Challenge *challenge = NULL;

    cout
         << "You currently have " << YELLOW << points << " points" << RESET << ". What do you want to do?" << endl
         << RED    << "  0. " << RESET << " List Challenges" << endl
         << YELLOW << "  1. " << RESET << " Make Challenge" << endl
         << GREEN << "  2. " << RESET << " Release Challenge" << endl
         << CYAN  << "  3. " << RESET << " Break Challenge" << endl
         << BLUE   << "  4. " << RESET << " Solve Challenge" << endl
         << MAGENTA   << "  5. " << RESET << " Quit" << endl
         << ">_ ";

    if (!(cin >> choice)) {
        cin.clear();
        cin.ignore();

        if(cin.eof())
            return true;

        throw new InvalidChoiceException();
    }

    cin.ignore(numeric_limits<streamsize>::max(),'\n');

    switch (choice) {
        case LIST:
            list();
            break;

        case MAKE:
            make_chall();
            break;

        case RELEASE:
            release_chall();
            break;

        case BREAK:
            break_chall();
            break;

        case SOLVE:
            solve_chall();
            break;

        case QUIT:
            return true;

        default:
            throw new InvalidChoiceException(choice);
    }

    return false;
}

extern void* __stack_chk_guard;
extern "C" void __real___stack_chk_fail();
extern "C" void __wrap___stack_chk_fail()
{
    throw new SSP();
}

extern "C" void enter_flag(char *ptr) {
    std::cout << "Enter flag: " << std::flush;

    if (scanf("%s", ptr) == EOF) {
        throw new InvalidFlagException();
    }
}


int main() {
    cout << "Welcome to the exceptionally good CTF Simulator 9000++!" << endl;
    CTF *ctf = new CTF();
    ctf->play();
}