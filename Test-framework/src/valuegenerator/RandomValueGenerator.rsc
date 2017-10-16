module valuegenerator::RandomValueGenerator

// Project imports
// Dependency imports
// Rebel imports
import lang::ExtendedSyntax;
// Rascal imports
import IO;
import ParseTree;
import List;
import String;
import util::Math;

// Minimum: including. So: if 0, then 0 can be a result value when determining it random.
// Maximum: including. So: if 10, then 10.00 is max result value when determining random.
alias RandomValueProps = tuple[Type tipe, real min, real max, bool allowZero];

private int MAX_TRIES = 100;

public real genRandomInteger(real min, real max, bool allowZero) {
    real result = genRandomInteger(min, max);
    int tries = 0;
    while ((result == 0.0 && !allowZero)) {
        result = genRandomInteger(min, max);
        tries += 1;
        if (tries >= MAX_TRIES) {
            assert(false) : "Maximum tries has been triggered when generating random integer with min:<min> max:<max> allowZero:<allowZero> tries:<tries>";
        }
    }
    return result;
}

public real genRandomDouble(real min, real max, bool allowZero) {
    real result = genRandomDouble(min, max);
    int tries = 0;
    while ((result == 0.0 && !allowZero) || tries > 10) {
        result = genRandomDouble(min, max);
        tries += 1;
        if (tries >= MAX_TRIES) {
            assert(false) : "Maximum tries has been triggered when generating random integer with min:<min> max:<max> allowZero:<allowZero>";
        }
    }
    return result;
}

@javaClass{valuegenerator.RandomValueGenerator}
java real genRandomInteger(real min, real max);

@javaClass{valuegenerator.RandomValueGenerator}
java real genRandomDouble(real min, real max);
