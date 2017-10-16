package valuegenerator;

import java.util.concurrent.ThreadLocalRandom;

import io.usethesource.vallang.IReal;
import io.usethesource.vallang.IBool;
import io.usethesource.vallang.IValueFactory;

public class RandomValueGenerator {
    
    private final IValueFactory values;

    public RandomValueGenerator(final IValueFactory values) {
    	this.values = values;
    }
    
    public IReal genRandomInteger(final IReal min, final IReal max) {
    	int minInt = (int) min.doubleValue();
    	int maxInt = (int) max.doubleValue();
    	if (minInt == maxInt) {
    		// Min and max are including, so return it since these are equal
    		return values.real(minInt);
    	} else {
    		// Determine random value
	    	int randomInt = ThreadLocalRandom.current().nextInt(minInt, maxInt);
	    	return values.real(randomInt);
    	}
    }
    
    public IReal genRandomDouble(final IReal min, final IReal max) {
    	if (min.doubleValue() == max.doubleValue()) {
    		// Min and max are including, so return it since these are equal
			return min;
    	} else {
    		// Determine random value
	    	double random = ThreadLocalRandom.current().nextDouble(min.doubleValue(), max.doubleValue());
	    	double result = round(random, 2); 
	    	return values.real(result);
    	}
    }
    
    private double round(double value, int scale) {
        return Math.round(value * Math.pow(10, scale)) / Math.pow(10, scale);
    }
}