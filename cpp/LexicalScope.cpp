
#include "LexicalScope.h"

shared_ptr<Declaration> LexicalScope::lookup(const string &name) const {
    auto it = bindings.find(name);
    if (it != bindings.end()) {
        shared_ptr<Declaration> value = it->second;
        return value;
    } else if (parent) {
        return parent->lookup(name);
    } else {
        return shared_ptr<Declaration>();
    }
}

void LexicalScope::bind(const string &name, const shared_ptr<Declaration> &value) {
    bindings[name] = value;
    bindingList.push_back(value);
}

void LexicalScope::import(const shared_ptr<LexicalScope> &scope)
{
    for (auto it = scope->bindings.cbegin(); it != scope->bindings.cend(); ++it) {
        //FIXME only if no conflicts
        bind(it->first, it->second);
    }
}

void LexicalScope::visit(DeclarationVisitor &visitor) {
    //cerr << "lexical scope visit " << name << endl;
    for (int i = 0; i < bindingList.size(); i++) {
        shared_ptr<Declaration> decl = bindingList[i];
        //cerr << "   lexical scope visit " << decl->name << endl;
        visitor.visitDeclaration(decl);
        if (decl->enumDeclaration())
            visitor.visitEnumDeclaration(decl->enumDeclaration());
        else if (decl->functionDefinition())
            visitor.visitFunctionDefinition(decl->functionDefinition());
        else if (decl->interfaceDeclaration())
            visitor.visitInterfaceDeclaration(decl->interfaceDeclaration());
        else if (decl->methodDeclaration())
            visitor.visitMethodDeclaration(decl->methodDeclaration());
        else if (decl->moduleDefinition())
            visitor.visitModuleDefinition(decl->moduleDefinition());
        else if (decl->structDeclaration())
            visitor.visitStructDeclaration(decl->structDeclaration());
        else if (decl->typeSynonymDeclaration())
            visitor.visitTypeSynonymDeclaration(decl->typeSynonymDeclaration());
        else if (decl->unionDeclaration())
            visitor.visitUnionDeclaration(decl->unionDeclaration());
    }
}