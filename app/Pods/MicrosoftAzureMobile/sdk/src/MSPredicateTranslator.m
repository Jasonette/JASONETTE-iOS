// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSPredicateTranslator.h"
#import "MSNaiveISODateFormatter.h"
#import "MSError.h"
#import "MSDateOffset.h"

#pragma mark * NSExpression Function String Constants


static NSString *const addFunction = @"add:to:";
static NSString *const subFunction =@"from:subtract:";
static NSString *const mulFunction = @"multiply:by:";
static NSString *const divFunction = @"divide:by:";
static NSString *const modFunction = @"modulus:by:";
static NSString *const ceilingFunction = @"ceiling:";
static NSString *const floorFunction = @"floor:";
static NSString *const toUpperFunction =@"uppercase:";
static NSString *const toLowerFunction = @"lowercase:";
static NSString *const truePredicate = @"TRUEPREDICATE";
static NSString *const falsePredicate = @"FALSEPREDICATE";


#pragma mark * Filter Query String Constants


static NSString *const openParentheses = @"(";
static NSString *const closeParentheses = @")";
static NSString *const comma = @",";

static NSString *const operatorOpenParentheses = @"%@(";
static NSString *const operatorWhitespace = @" %@ ";

static NSString *const notOperator = @"not";
static NSString *const andOperator = @"and";
static NSString *const orOperator = @"or";
static NSString *const lessThanOperator = @"lt";
static NSString *const lessThanOrEqualsOperator = @"le";
static NSString *const greaterThanOperator = @"gt";
static NSString *const greaterThanOrEqualsOperator = @"ge";
static NSString *const equalsOperator = @"eq";
static NSString *const notEqualsOperator = @"ne";
static NSString *const addOperator = @"add";
static NSString *const subOperator = @"sub";
static NSString *const mulOperator =  @"mul";
static NSString *const divOperator = @"div";
static NSString *const modOperator =  @"mod";
static NSString *const ceilingOperator = @"ceiling";
static NSString *const floorOperator = @"floor";
static NSString *const toUpperOperator = @"toupper";
static NSString *const toLowerOperator = @"tolower";
static NSString *const startsWithOperator = @"startswith";
static NSString *const endsWithOperator = @"endswith";
static NSString *const substringOfOperator = @"substringof";

static NSString *const nullConstant = @"null";
static NSString *const stringConstant = @"'%@'";
static NSString *const trueConstant = @"true";
static NSString *const falseConstant = @"false";
static NSString *const decimalConstant = @"%@m";
static NSString *const floatConstant = @"%gf";
static NSString *const doubleConstant = @"%gd";
static NSString *const intConstant = @"%d";
static NSString *const longConstant = @"%ld";
static NSString *const longLongConstant = @"%lldl";
static NSString *const dateTimeConstant = @"datetime'%@'";
static NSString *const dateTimeOffsetConstant = @"datetimeoffset'%@'";
static NSString *const alwaysTrueConstant = @"(1 eq 1)";
static NSString *const alwaysFalseConstant = @"(1 eq 0)";
static NSString *const guidConstant = @"guid'%@'";


#pragma mark * MSPredicateTranslator Implementation


@implementation MSPredicateTranslator

static NSDictionary *staticFunctionInfoLookup;


#pragma mark * Public Static Methods


+(NSString *) queryFilterFromPredicate:(NSPredicate *)predicate
                               orError:(NSError **)error
{
    NSString *queryFilter = [MSPredicateTranslator visitPredicate:predicate];
    
    if (!queryFilter && error) {
        *error = [MSPredicateTranslator errorForUnsupportedPredicate];
    }

    return queryFilter;
}


#pragma mark * Private Visit Predicate Methods


+(NSString *) visitPredicate:(NSPredicate *)predicate
{
    NSString *result = nil;
    
    // Determine which subclass of NSPredicate we have and
    // then call the appropriate visit*() method
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        
        result = [MSPredicateTranslator visitComparisonPredicate:
                  (NSComparisonPredicate *)predicate];
    }
    else if ([predicate isKindOfClass:[NSCompoundPredicate class]]){
        
        result = [MSPredicateTranslator visitCompoundPredicate:
                  (NSCompoundPredicate *)predicate];
    }
    else {
        NSString *predicteFormat = predicate.predicateFormat;
        if ([predicteFormat isEqualToString:truePredicate]){
            result = alwaysTrueConstant;
        }
        else if ([predicteFormat isEqualToString:falsePredicate]) {
            result = alwaysFalseConstant;
        }
    }
    
    
    return result;
}

+(NSString *) visitPredicates:(NSArray *)predicates
                 withOperator:(NSString *)operator
             useInfixNotation:(BOOL)useInfix
{
    NSMutableString *result = [NSMutableString string];
    
    // Determine the strings to use depending on infix or prefix notation
    NSString *openParenthesesString = (useInfix) ?
        openParentheses :
        [NSString stringWithFormat:operatorOpenParentheses, operator];
    
    NSString *predicateSeparatorString = (useInfix) ?
        [NSString stringWithFormat:operatorWhitespace, operator] :
        comma;
    
    // Start with the open parentheses string
    [result appendString:openParenthesesString];
    
    // Iterate through the predicates
    BOOL firstPredicate = YES;
    for (NSPredicate *predicate in predicates) {

        if (!firstPredicate) {
            [result appendString:predicateSeparatorString];
        }
        firstPredicate = NO;
        
        NSString *subResult = [MSPredicateTranslator visitPredicate:predicate];
        if (!subResult) {
            result = nil;
            break;
        }
        else {
            [result appendString:subResult];
        }
    }
    
    // Close the parentheses
    [result appendString:closeParentheses];

    return result;
}

+(NSString *) visitComparisonPredicate:(NSComparisonPredicate *)predicate
{
    NSString *result = nil;
    
    BOOL useInfixNotation = YES;
    BOOL leftThenRightExpressions = YES;
    NSPredicate *replacementPredicate = nil;
    NSString *operator = nil;

    
    // If the case insensitive option is being used, wrap both expressions
    // in tolower() function calls
    if ((predicate.options & NSCaseInsensitivePredicateOption) ==
         NSCaseInsensitivePredicateOption) {
        
        predicate =
        [MSPredicateTranslator replacementPredicateForCaseInsensitivePredicate:predicate];
    }
    
    // Lookup the operator and whether using infix notation, or determine
    // if this predicte should be replaced with another equivalent
    // predicate.
    switch (predicate.predicateOperatorType) {
        case NSLessThanPredicateOperatorType:
            operator = lessThanOperator;
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            operator = lessThanOrEqualsOperator;
            break;
        case NSGreaterThanPredicateOperatorType:
            operator = greaterThanOperator;
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            operator = greaterThanOrEqualsOperator;
            break;
        case NSEqualToPredicateOperatorType:
            operator = equalsOperator;
            break;
        case NSNotEqualToPredicateOperatorType:
            operator = notEqualsOperator;
            break;
        case NSBeginsWithPredicateOperatorType:
            useInfixNotation = NO;
            operator = startsWithOperator;
            break;
        case NSEndsWithPredicateOperatorType:
            useInfixNotation = NO;
            operator = endsWithOperator;
            break;
        case NSContainsPredicateOperatorType:
            useInfixNotation = NO;
            leftThenRightExpressions = NO;
            operator = substringOfOperator;
            break;
        case NSInPredicateOperatorType:
            replacementPredicate =
            [MSPredicateTranslator replacementPredicateForInPredicate:predicate];
            break;
        case NSBetweenPredicateOperatorType:
            replacementPredicate =
            [MSPredicateTranslator replacementPredicateForBetweenPredicate:predicate];
            break;
        case NSMatchesPredicateOperatorType:
        case NSLikePredicateOperatorType:
        case NSCustomSelectorPredicateOperatorType:
        default:
            // Not supported, so operator remains nil
            break;
    }

    if (replacementPredicate) {
        result = [MSPredicateTranslator visitPredicate:replacementPredicate];
    }
    else if (operator) {
        
        // Get the expressions in the correct order for the operator if not
        // already set
        NSArray *expressions = nil;
        if (leftThenRightExpressions) {
            expressions = [NSArray arrayWithObjects:
                           predicate.leftExpression,
                           predicate.rightExpression, nil];
        }
        else
        {
            expressions = [NSArray arrayWithObjects:
                           predicate.rightExpression,
                           predicate.leftExpression, nil];
        }
        
        // Now visit the expressions
        result = [MSPredicateTranslator visitExpressions:expressions
                                            withOperator:operator
                                        useInfixNotation:useInfixNotation];

    }
    
    return result;
}

+(NSString *) visitCompoundPredicate:(NSCompoundPredicate *)predicate
{
    NSString *result = nil;

    NSString *operator = nil;
    BOOL useInfixNotation= YES;
    
    // Determine the correct operator and if this has a single operand or
    // multiple
    switch (predicate.compoundPredicateType) {
        case NSNotPredicateType:
            operator = notOperator;
            useInfixNotation = NO;
            break;
        case NSAndPredicateType:
            operator = andOperator;
            break;
        case NSOrPredicateType:
            operator = orOperator;
            break;
        default:
            // Unknown operator, so operator remains nil
            break;
    }
    
    if (operator) {
        result = [MSPredicateTranslator visitPredicates:predicate.subpredicates
                                           withOperator:operator
                                       useInfixNotation:useInfixNotation];
    }
    
    return result;
}

+(NSComparisonPredicate *) replacementPredicateForCaseInsensitivePredicate:(NSComparisonPredicate *)predicate
{
    NSExpression *newRightExpression =
    [NSExpression expressionForFunction:toLowerFunction
                              arguments:@[predicate.rightExpression]];
    
    NSExpression *newLeftExpression =
    [NSExpression expressionForFunction:toLowerFunction
                              arguments:@[predicate.leftExpression]];
    
    NSPredicate *replacementPredicate =
    [NSComparisonPredicate predicateWithLeftExpression:newLeftExpression
                                      rightExpression:newRightExpression
                                      modifier:predicate.comparisonPredicateModifier
                                      type:predicate.predicateOperatorType
                                      options:predicate.options];
    
    return (NSComparisonPredicate *)replacementPredicate;
}

+(NSPredicate *) replacementPredicateForInPredicate:(NSComparisonPredicate *)predicate
{
    NSMutableArray *subPredicates = [NSMutableArray array];
    
    // The rightExpression will be an array of expressions/items. For each
    // of these expressions/items we will build an equals predicate and then
    // 'or' together all of these subpredicates in order to replace this
    // 'IN' predicate
    NSExpression *rightExpression = predicate.rightExpression;
    NSExpression *leftExpression = predicate.leftExpression;
    
    // ConstantValue will be an array in this case
    for (id item in rightExpression.constantValue) {
        
        // The new right-side expression we are going to build
        NSExpression *newRightExpression = [MSPredicateTranslator ensureExpression:item];
        
        // Build the equals-to predicate and add it to the array of subPredicates
        NSPredicate *subPredicate =
        [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                               rightExpression:newRightExpression
                               modifier:predicate.comparisonPredicateModifier
                               type:NSEqualToPredicateOperatorType
                               options:predicate.options];
    
        [subPredicates addObject:subPredicate];
    }
    
    // Return the or'd compound of all of the sub predicates.
    return [NSCompoundPredicate orPredicateWithSubpredicates:subPredicates];
}

+(NSPredicate *) replacementPredicateForBetweenPredicate:(NSComparisonPredicate *)predicate
{
    NSMutableArray *subPredicates = [NSMutableArray array];
    
    // The rightExpression will be an array of 2 expressions/items. For the
    // first we will build a greater than or equals predicate and for the second
    // we will build a less than or equals predicate. Lastly, we will 'and'
    // together these two subpredicates in order to replace this
    // 'BETWEEN' predicate
    NSExpression *rightExpression = predicate.rightExpression;
    NSExpression *leftExpression = predicate.leftExpression;
    
    // First, we'll get the lower and upper bounds
    NSArray *bounds = rightExpression.constantValue;
    id lowerBound = [bounds objectAtIndex:0];
    id upperBound = [bounds objectAtIndex:1];
    
    // If variable subsitution was used, the items might be actual values instead
    // of Expressions, so we need to ensure they are expressions
    NSExpression *lowerBoundExpression = [MSPredicateTranslator ensureExpression:lowerBound];
    NSExpression *upperBoundExpression = [MSPredicateTranslator ensureExpression:upperBound];
    
    // We'll create the lower bound predicate (greater or equal)
    NSPredicate *lowerSubPredicate =
        [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                           rightExpression:lowerBoundExpression
                                                  modifier:predicate.comparisonPredicateModifier
                                                      type:NSGreaterThanOrEqualToPredicateOperatorType
                                                   options:predicate.options];
    [subPredicates addObject:lowerSubPredicate];
    
    // We'll create the upper bound predicate (less or equal)
    NSPredicate *upperSubPredicate =
        [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                       rightExpression:upperBoundExpression
                                              modifier:predicate.comparisonPredicateModifier
                                                  type:NSLessThanOrEqualToPredicateOperatorType
                                               options:predicate.options];
    [subPredicates addObject:upperSubPredicate];
    
    // Return the and'd compound of all of the sub predicates.
    return [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
}

+(NSExpression *) ensureExpression:(id) item
{
    NSExpression *expression;
    
    // If variable substitution was used, we can get items that are
    // not expressions but need to be for predicate re-writing purposes.
    if ([item isKindOfClass:[NSExpression class]]) {
        expression = item;
    }
    else {
        expression = [NSExpression expressionForConstantValue:item];
    }
    
    return expression;
}


#pragma mark * Private Visit Expression Methods


+(NSString *) visitExpression:(NSExpression *)expression
{
    NSString *result = nil;
    
    switch (expression.expressionType)
    {
        case NSConstantValueExpressionType:
            result = [MSPredicateTranslator visitConstant:expression.constantValue];
            break;
        case NSKeyPathExpressionType:
            result = expression.keyPath;
            break;
        case NSFunctionExpressionType:
            result = [MSPredicateTranslator visitFunction:expression.function
                                            withArguments:expression.arguments];
            break;
        case NSEvaluatedObjectExpressionType:
        case NSVariableExpressionType:
        case NSAggregateExpressionType:
        case NSSubqueryExpressionType:
        case NSUnionSetExpressionType:
        case NSIntersectSetExpressionType:
        case NSMinusSetExpressionType:
        case NSBlockExpressionType:
        default:
            // Not supported so result remains nil
            break;
    }
    
    return result;
}

+(NSString *) visitExpressions:(NSArray *)expressions
                 withOperator:(NSString *)operator
             useInfixNotation:(BOOL)useInfix
{
    NSMutableString *result = [NSMutableString string];
    
    // Determine the strings to use depending on infix or prefix notation
    NSString *openParenthesesString = (useInfix) ?
    openParentheses :
    [NSString stringWithFormat:operatorOpenParentheses, operator];
    
    NSString *expressionSeparatorString = (useInfix) ?
    [NSString stringWithFormat:operatorWhitespace, operator] :
    comma;
    
    // Start with the open parentheses string
    [result appendString:openParenthesesString];
    
    // Iterate through the expressions
    BOOL firstExpression = YES;
    for (NSExpression *expression in expressions) {
        
        if (!firstExpression) {
            [result appendString:expressionSeparatorString];
        }
        firstExpression = NO;
        
        NSString *subResult = [MSPredicateTranslator visitExpression:expression];
        if (!subResult) {
            result = nil;
            break;
        }
        else {
            [result appendString:subResult];
        }
    }
    
    // Close the parentheses
    [result appendString:closeParentheses];
    
    return result;
}

+(NSString *) visitFunction:(NSString *)function
              withArguments:(NSArray *)arguments
{
    NSString *result = nil;
    
    // There are a lot of NSPRedicate functions we don't support because
    // the query string syntax doesn't have equivalents.
    NSDictionary *functionInfos = [MSPredicateTranslator functionInfoLookup];
    
    // Get info about how to translate the function
    NSArray *functionInfo = [functionInfos objectForKey:function];
    if (functionInfo) {
                      
        // Get the operator and the use of infixNotation
        NSString *operator = [functionInfo objectAtIndex:0];
        BOOL useInfixNotation = [[functionInfo objectAtIndex:1] boolValue];
        
        result = [MSPredicateTranslator visitExpressions:arguments
                                            withOperator:operator
                                        useInfixNotation:useInfixNotation];
    }
    
    return result;
}

+(NSString *) visitConstant:(id)constant
{
    NSString *result = nil;
    
    // The constant can be a nil/null, so check that first
    if (constant == nil || constant == [NSNull null]) {
        result = nullConstant;
    }
    else if ([constant isKindOfClass:[NSString class]]) {
        result = [MSPredicateTranslator visitStringConstant:constant];
    }
    else if ([constant isKindOfClass:[MSDateOffset class]]) {
        result = [MSPredicateTranslator visitDateOffsetConstant:constant];
    }
    else if ([constant isKindOfClass:[NSDate class]]) {
        result = [MSPredicateTranslator visitDateConstant:constant];
    }
    else if ([constant isKindOfClass:[NSDecimalNumber class]]) {
        const NSDecimal decimal = [constant decimalValue];
        result = [NSString stringWithFormat:decimalConstant,
                  NSDecimalString(&decimal, nil)];
    }
    else if ([constant isKindOfClass:[NSNumber class]]) {
        // Except for decimals, all number types and bools will be this case
        result = [MSPredicateTranslator visitNumberConstant:constant];
    }
    else if ([constant isKindOfClass:[NSUUID class]]) {
        result = [MSPredicateTranslator visitGuidConstant:constant];
    }
    
    return result;
}

+(NSString *) visitStringConstant:(NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    return [NSString stringWithFormat:stringConstant, string];
}

+(NSString *) visitDateConstant:(NSDate *)date
{
    NSString *result = nil;
    
    // Get the formatter
    MSNaiveISODateFormatter *formatter =
    [MSNaiveISODateFormatter naiveISODateFormatter];
    
    // Try to get a formatted date as a string
    NSString *dateString = [formatter stringFromDate:date];
    
    if (dateString) {
        result = [NSString stringWithFormat:dateTimeConstant, dateString];
    }
    
    return result;
}

+(NSString *) visitDateOffsetConstant:(MSDateOffset *)dateOffset
{
    NSString *result = nil;
    
    // Get the formatter
    MSNaiveISODateFormatter *formatter =
    [MSNaiveISODateFormatter naiveISODateFormatter];
    
    // Try to get a formatted date as a string
    NSString *dateString = [formatter stringFromDate:dateOffset.date];
    
    if (dateString) {
        result = [NSString stringWithFormat:dateTimeOffsetConstant, dateString];
    }
    
    return result;
}

+(NSString *) visitNumberConstant:(NSNumber *)number
{
    NSString *result = nil;
    
    // We need to determine the c-language type of the number in order
    // to properly format it
    const char *cType = [number objCType];
    
    // 64-bit [NSNumber numberWithBool:] returns 'c' (char) and don't match the BOOL encode of 'B'
    if (strcmp(@encode(BOOL), cType) == 0 || strcmp(@encode(char), cType) == 0) {
        result = [number boolValue] ? trueConstant : falseConstant;
    }
    else if(strcmp(@encode(int), cType) == 0) {
        // 32-bit integers don't have a suffix so just the number string works
        result = [NSString stringWithFormat:intConstant, [number intValue]];
    }
    else if(strcmp(@encode(double), cType) == 0) {
        result = [NSString stringWithFormat:doubleConstant, [number doubleValue]];
    }
    else if(strcmp(@encode(float), cType) == 0) {
        result = [NSString stringWithFormat:floatConstant, [number floatValue]];
    }
    else if(strcmp(@encode(long long), cType) == 0) {
        result = [NSString stringWithFormat:longLongConstant, [number longLongValue]];
    }
    else if(strcmp(@encode(long), cType) == 0) {
        result = [NSString stringWithFormat:longConstant, [number longValue]];
    } 

    return result;
}

+(NSString *) visitGuidConstant:(NSUUID *) guid
{
    return [NSString stringWithFormat:guidConstant, guid.UUIDString];
}

+(NSDictionary *) functionInfoLookup
{
    if (staticFunctionInfoLookup == nil) {
        
        // Value is an array with (1) the operator function name, (2)
        // a bool that indicates if the function uses infix
        // notation
        staticFunctionInfoLookup = @{
            addFunction : @[ addOperator, @(YES)],
            subFunction : @[ subOperator, @(YES)],
            mulFunction : @[ mulOperator, @(YES)],
            divFunction : @[ divOperator, @(YES)],
            modFunction : @[ modOperator, @(YES)],
            ceilingFunction : @[ ceilingOperator, @(NO)],
            floorFunction : @[ floorOperator, @(NO)],
            toUpperFunction : @[ toUpperOperator, @(NO)],
            toLowerFunction : @[ toLowerOperator, @(NO)],
        };
    }
    
    return  staticFunctionInfoLookup;
}


#pragma mark * NSError Generation Methods


+(NSError *) errorForUnsupportedPredicate
{
    NSString *description = NSLocalizedString(@"The predicate is not supported.", nil);
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey :description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:MSPredicateNotSupported
                           userInfo:userInfo];
}

@end
