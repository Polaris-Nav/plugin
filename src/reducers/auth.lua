local e = _G.PolarisNav

local save = e.op.persistent_save
local load = e.op.persistent_load

local function set_auth(uid, tok, ses, code, att, guest)
	local auth = {
		UserId = tonumber(uid);
		session = ses;
		token = tok;
		Code = code;
		attempts = att;
		is_guest = guest;
	}
	local p = e.plugin
	save('auth', {
		['user-id'] = uid;
		['refresh-token'] = tok;
		['session'] = ses;
	})
	return auth
end

return function(action, old, new, nxt)
	if action.type == '@@INIT' then
		local savedAuth = load('auth')
		new.auth = set_auth(
			savedAuth['user-id'] or nil,
			savedAuth['refresh-token'] or nil,
			savedAuth['session'] or nil,
			nil,
			0,
			false
		)
		return
	end

	local name = nxt()
	if name == 'link' then
		name = nxt()
		if name == nil then
			new.auth = set_auth(
				action.id,
				action.token,
				action.session,
				nil,
				0,
				false
			)
		elseif name == 'clear' then
			new.auth = set_auth(
				nil,
				nil,
				nil,
				nil,
				0,
				true
			)
		else
			error('reducer does not implement ' .. name)
		end
	elseif name == 'login' then
		name = nxt()
		if name == nil then
			new.auth = set_auth(
				old.auth.UserId,
				old.auth.token,
				action.session,
				nil,
				0,
				false
			)
		elseif name == 'fail' then
			local attempts = old.auth.attempts + 1
			if attempts >= 3 then
				new.auth = set_auth(
					nil,
					nil,
					nil,
					nil,
					0,
					true
				)
			else
				new.auth = set_auth(
					old.auth.UserId,
					old.auth.token,
					nil,
					nil,
					attempts,
					true
				)
			end
		elseif name == 'clear' then
			new.auth = set_auth(
				old.auth.UserId,
				old.auth.token,
				nil,
				nil,
				0,
				true
			)
		else
			error('reducer does not implement ' .. name)
		end
	else
		error('reducer does not implement ' .. name)
	end
end