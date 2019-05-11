function handle_macro(@nospecialize(x), state) end
function handle_macro(x::EXPR, state)
    x.typ !== MacroCall && return
    if x.args[1].typ === MacroName
        state(x.args[1])
        if _points_to_Base_macro(x.args[1], "deprecate", state) && length(x.args) == 3
            if CSTParser.is_func_call(x.args[2])
                # add deprecated method
                # add deprecated function binding and args in new scope
                CSTParser.setbinding!(x.args[2], x)
                CSTParser.mark_sig_args!(x.args[2])
                s0 = state.scope # store previous scope
                ignorewherescope = state.ignorewherescope
                state.scope = Scope(s0, Dict(), nothing)
                x.scope = state.scope # tag new scope to generating expression
                state.ignorewherescope = true
                state(x.args[2])
                state(x.args[3])
                state.scope = s0
                state.ignorewherescope = ignorewherescope
            elseif isidentifier(x.args[2])
                CSTParser.setbinding!(x.args[2], x)
            end
        elseif _points_to_Base_macro(x.args[1], "enum", state)
            for i = 2:length(x.args)
                if !(x.args[i].typ === PUNCTUATION)
                    CSTParser.setbinding!(x.args[i], x)
                end
            end
        elseif _points_to_Base_macro(x.args[1], "nospecialize", state)
            for i = 2:length(x.args)
                if !(x.args[i].typ === PUNCTUATION)
                    CSTParser.setbinding!(x.args[i], x)
                end
            end
        end
    end
end


function _points_to_Base_macro(x::EXPR, name, state)
    length(x.args) == 2 && isidentifier(x.args[2]) && x.args[2].val == name && x.args[2].ref == getsymbolserver(state.server)["Base"].vals[string("@", name)]
end
