# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2021-2023 Dyne.org foundation <foundation@dyne.org>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

export DEST=${1}; time ./doFlow.sh ${DEST} N N > MP-${DEST}.log
# export DEST=shared; time ./curl.sh ${DEST} N N > MP-${DEST}.log

# echo -e "Result from trace"
# cat MP-${1}.log | grep -v 'CET 2022' | jq '.trace[] | .id + " " + .__typename + " " + .note'

# echo -e "Result from track"
# cat MP-${1}.log | grep -v 'CET 2022' | jq '.track[] | .id + " " + .__typename + " " + .note'

