(function(i) {
    // Enable logging - log using logger.warn(....) - goes to openhab2.log
    var logger = Java.type("org.slf4j.LoggerFactory").getLogger("cm-to-mm.js");

    // Items come into the trasnform as strings - we need to parse it as a float
    var cm = parseFloat(i);
    // Perform the math
    var mm = (cm * 10);
    // And return the result back to the item (still as a float var)
    //logger.warn(mm);
    return mm;
})(input)
