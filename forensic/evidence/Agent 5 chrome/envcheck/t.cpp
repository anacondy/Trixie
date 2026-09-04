#include <iostream>
#include <vector>
#include <algorithm>
int main(){std::vector<int> v(1000000); for(size_t i=0;i<v.size();i++)v[i]=(int)(v.size()-i); std::sort(v.begin(),v.end()); std::cout<<"cpp ok "<<v[0]<<"\n";}
