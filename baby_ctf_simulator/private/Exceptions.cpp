#include "chall.hpp"
#include "Exceptions.hpp"

AlreadyBrokenChallengeException::AlreadyBrokenChallengeException(Challenge* chall): chall(chall) {
    std::stringstream ss;
    ss << "Yo you already broke " << chall->name << "!";
    msg = ss.str();
}

AlreadyReleasedChallengeException::AlreadyReleasedChallengeException(Challenge* chall): chall(chall) {
    std::stringstream ss;
    ss << "Yo you already released " << chall->name << "!";
    msg = ss.str();
}

AlreadySolvedException::AlreadySolvedException(std::string _name):
    name(_name) 
{
    std::stringstream ss;
    ss << "Yo cheatah! You can only solve " << name << " once!";
    msg = ss.str();
}

InvalidChoiceException::InvalidChoiceException(double _choice): choice(_choice) {
    std::stringstream ss;
    ss << "Can you even read? " << choice << " iz not a valid choice!";
    msg = ss.str();
}

InvalidChoiceException::InvalidChoiceException():
    choice(-1), msg("Hey numpty! The numbahs are at the top of your keyboard, rite?") {}

DuplicateNameException::DuplicateNameException(std::string _name):
    name(_name)
{
    std::stringstream ss;
    ss << "Uh... u drunk? You already made a challenge called " << name << "!";
    msg = ss.str();
};

NoSuchChallengeException::NoSuchChallengeException(std::string _name):
    name(_name)
{
    std::stringstream ss;
    ss << "Uh... maybe check the challenge list first? There's no challenge called " << name << "!";
    msg = ss.str();
};

BrokenChallengeException::BrokenChallengeException(std::string _name):
    name(_name) 
{
    std::stringstream ss;
    ss << "Sowwy u can't solve " << name << " right now, it's borken!";
    msg = ss.str();
};