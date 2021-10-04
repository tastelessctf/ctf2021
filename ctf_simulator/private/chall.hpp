#pragma once

#include <iostream>
#include <string.h>
#include <string>
#include <map>
#include "Exceptions.hpp"

using namespace std;

class Challenge {
    public:
        string name;
        Challenge();
        Challenge(string& name): name(name) {};
        virtual ~Challenge() {}
};

class UnreleasedChallenge: public Challenge {
    public:
        UnreleasedChallenge() {};
        friend ostream& operator<<(ostream& os, const UnreleasedChallenge& self);
};

class ReleasedChallenge: public Challenge {
    private:
        void set_points();
        void set_flag();
    public:
        int points;
        string flag;
        bool solved;
        ReleasedChallenge();
        ReleasedChallenge(Challenge* uc);
        int solve();

        friend ostream& operator<<(ostream& os, const ReleasedChallenge& self);
};

class BrokenChallenge: public Challenge {
    public:
        string reason;
        BrokenChallenge() {};
        BrokenChallenge(Challenge* uc);
        friend ostream& operator<<(ostream& os, const BrokenChallenge& self);
};

enum menu {
    LIST = 0,
    MAKE,
    RELEASE,
    BREAK,
    SOLVE,
    QUIT
};

class CTF {
    private:
        int points;
        std::map<std::string, Challenge*> challenges;

        bool menu();

        void make_chall();
        void release_chall();
        void break_chall();
        void solve_chall();

    public:
        CTF() {};
        void play();
        void list();
};

extern "C" int check_flag(const char* expected, size_t len);
