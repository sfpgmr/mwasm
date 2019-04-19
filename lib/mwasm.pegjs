//
// Parsing Exprettion Grammar of SGL2
// ==================
//

{
  function filledArray(count, value) {
    return Array.apply(null, new Array(count))
      .map(function() { return value; });
  }

  function extractOptional(optional, index) {
    return optional ? optional[index] : null;
  }

  function extractList(list, index) {
    return list.map(function(element) { return element[index]; });
  }

  function buildList(head, tail, index) {
    return [head].concat(extractList(tail, index));
  }

  function buildBinaryExpression(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        nodeType: "BinaryExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }

  function buildLogicalExpression(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        nodeType: "LogicalExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }

  function optionalList(value) {
    return value !== null ? value : [];
  }

  class Context {
    eval(code){
      eval(code);
    }
  }

  var context = new Context();
}

start = tokens:Token* {
  return tokens.filter(d=>d)
}

Token =  Comment / StringLiteral / CodeBlock / Identifier / Separator / __

__
  = head:(LineTerminatorSequence / _ )+ {return head.find(d=>d=='LineTerminator') ? '\n' : null;}

_
  = WhiteSpace+ {return null;}

SourceCharacter
  = .

Identifier = $IdChar+

IdChar = [0-9a-zA-Z!#$%&'*+-.\\:<=>?@^_`~!] 

Separator = "(" / ")"

StringLiteral = $('"' ('\\"' / [^"])* '"')

Comment = LineComment / BlockComment

LineComment = $(";;" [^\u000a]* ("\u000a" / EOF))  
BlockComment = $("(;" BlockCommentChar* ";)")
BlockCommentChar = [^(;] / ';' !')' / '(' !';' / BlockComment

EOF = !.

WhiteSpace "whitespace"
  = "\t"
  / "\v"
  / "\f"
  / " "
  / "\u00A0"
  / "\uFEFF"
  / Zs

// Separator, Space
Zs = [\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]

LineTerminator
  = [\n\r\u2028\u2029]

LineTerminatorSequence "end of line"
  = ("\n"
  / "\r\n"
  / "\r"
  / "\u2028"
  / "\u2029") {return 'LineTerminator';}

  CodeBlock "code block"
  = "{" code:Code "}" {return '' + context.eval(code);}
  / "{" { error("Unbalanced brace."); }

Code
  = $((![{}] SourceCharacter)+ / "{" Code "}")* 


