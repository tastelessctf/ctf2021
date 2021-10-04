#pragma once

#include <sstream>

class Challenge;

class NonFatalException: public std::exception {
    public:
        virtual const char* what() const throw() = 0;
};

class UnreleasedChallengeException: public NonFatalException {
    public:
        UnreleasedChallengeException() {};
    
        virtual const char* what() const throw()
        {
            return "Unreleased";
        }
};

class AlreadyReleasedChallengeException: public NonFatalException {
    private:
        Challenge* chall;
        std::string msg;

    public:
        AlreadyReleasedChallengeException(Challenge* chall);

        virtual const char* what() const throw()
        {
            return msg.c_str();
        }
};

class AlreadyBrokenChallengeException: public NonFatalException {
    private:
        Challenge* chall;
        std::string msg;

    public:
        AlreadyBrokenChallengeException(Challenge* chall);

        virtual const char* what() const throw()
        {
            return msg.c_str();
        }
};

class BrokenChallengeException: public NonFatalException {
    private:
        std::string msg;
    
    public:
        std::string name;

        BrokenChallengeException(std::string _name);

        virtual const char* what() const throw()
        {
            return msg.c_str();
        }
};

class InvalidChoiceException: public NonFatalException {
    private:
        long choice;
        std::string msg;
    
    public:
        InvalidChoiceException(double _choice);
        InvalidChoiceException();

        virtual const char* what() const throw() {
            return msg.c_str();
        }
};

class AlreadySolvedException: public NonFatalException {
    private:
        std::string msg;
    
    public:
        std::string name;
        AlreadySolvedException(std::string _name);

        virtual const char* what() const throw()
        {
            return msg.c_str();
        }
};

class DuplicateNameException: public NonFatalException {
    private:
        std::string msg;

    public:
        std::string name;

        DuplicateNameException(std::string _name);

        virtual const char* what() const throw()
        {
            return msg.c_str();
        }
};

class InvalidInputException: public std::exception {
    public:
        InvalidInputException() {};

    virtual const char* what() const throw() {
        return "Invalid Input!";
    }
};

class SSP: public InvalidInputException {
    public:
        SSP() {};

    virtual const char* what() const throw() {
        return "Stash the smack for phun and prophit!";
    }
};

class NoChallengesYetException: public NonFatalException {
    public:
        virtual const char* what() const throw()
        {
            return "Hmm, looks like there aren't any challenges yet...";
        }
};

class NoSuchChallengeException: public NonFatalException {
    private:
        std::string msg;

    public:
        std::string name;

        NoSuchChallengeException(std::string _name);

        virtual const char* what() const throw()
        {
            return msg.c_str();
        }
};

class InvalidFlagException: public NonFatalException {
    public:
        virtual const char* what() const throw()
        {
            return "Try harder! You can do it!";
        }
};