#include <iostream>
#include "Colors.hpp"
#include "chall.hpp"

using namespace std;

ostream& operator<<(ostream& os, const ReleasedChallenge& rc) {
    os << "[" << GREEN << "RELEASED" << RESET << "]    == "
                    << rc.name << " ==" << endl
# ifdef DEBUG
                    << " Pointer: " << &rc << endl
# endif
                    << "  Points: " << rc.points << endl
                    << "  Solved: " << (rc.solved ? "true" : "false");
    return os;
}

ostream& operator<<(ostream& os, const UnreleasedChallenge& uc) {
    os << "[" << YELLOW << "UNRELEASED" << RESET << "]  == "
                << uc.name << " ==" <<endl
# ifdef DEBUG
                << " Pointer: " << &uc << endl
# endif
                ;
    return os;
}

ostream& operator<<(ostream& os, const BrokenChallenge& bc) {
    os << "[" << RED << "BROKEN" << RESET << "]      == "
                << bc.name << " ==" << endl
# ifdef DEBUG
                << " Pointer: " << &bc << endl
# endif
                << "  Reason: " << bc.reason;
    return os;
}