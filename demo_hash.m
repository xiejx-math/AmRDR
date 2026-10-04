function value=demo_hash(file)
% Compute a file SHA-256 without executing or modifying its contents.
f=fopen(file,'rb'); if f<0, error('demo:File','Cannot read %s.',file); end
cleanup=onCleanup(@()fclose(f));
digest=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(f)
    bytes=fread(f,1048576,'*uint8');
    digest.update(typecast(bytes,'int8'));
end
value=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
