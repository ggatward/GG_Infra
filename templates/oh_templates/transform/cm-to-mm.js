(function(i) {
  // Items come into the trasnform as strings - we need to parse it as a float
  var cm = parseFloat(i);
  // Perform the math and strip to 1 decimal place
  var mm = (cm * 10).toFixed(1);
  // Append the text string for units
  var returnString = mm + ' mm';
  // And return the result back to the item
  return returnString.trim();
})(input)
