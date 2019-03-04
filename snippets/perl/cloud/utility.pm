# UTILITY PACKAGE FOR CLOUD WORKSPACE

package utility;

use lib ".";
use constants;

use List::MoreUtils qw(any);

###################################################
# Check for platform
# The function checks if current platform is windows
###################################################
sub is_windows {
    return any { $_ eq $^O } @constants::WIN_PLATFORMS;
}

###################################################
# Get NetBackup file/directory path according to OS platform
# The function gets path as defined in constants
###################################################
sub get_nb_path {
    if (scalar (@_) == 0) {
        return undef
    }
    return @_[is_windows()];
}

###################################################
# Substitute variables in the string
# Example: 
#   build_string("Hello #1", "World") >> "Hello World"
###################################################
sub build_string {
    $cnt = scalar(@_);

    if ($cnt == 0) {
        return "";
    }
    elsif ($cnt == 1) {
        return @_[0];
    }
    else {
        $string = @_[0];
        for my $index (1..$cnt-1) {
            $string =~ s/#$index/@_[$index]/g;
        }
        return $string;
    }
}

1;