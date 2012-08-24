_G.bit = {
	new = function(str)
		return tonumber(str, 2)
	end,
	get = function(num, n, n2)
		if n2 then
			local total = 0
			local digitn = 0
			for i = n, n2 do
				total = total + 2^digitn*bit.get(num, i)
				digitn = digitn + 1
			end
			return total
		else
			local pn = 2^(n-1)
			return (num % (pn + pn) >= pn) and 1 or 0	
		end
	end,
	getstring = function(num, mindigit, sep)
		mindigit = mindigit or 0
		local pow = 0
		local tot = 1
		while tot <= num do
			tot = tot * 2
			pow = pow + 1
		end
		---
		if pow < mindigit then pow = mindigit end
		---
		local str = ""
		for i = pow, 1, -1 do
			str = str..bit.get(num, i)..(i==1 and "" or (sep or "-"))
		end
		return str
	end
}
