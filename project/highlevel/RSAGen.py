import rsa 


(pubkey, privkey) = rsa.newkeys(60)

print(pubkey)
print(privkey)

print(f"""
pub_key(e)  = {hex(privkey.e)}
priv_key(d) = {hex(privkey.d)}
modulus(n)  = {hex(privkey.n)}
""")

print(f"""
{hex(privkey.e)}
{hex(privkey.d)}
{hex(privkey.n)}
""")
